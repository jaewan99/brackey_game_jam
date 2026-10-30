class_name AIOpponent
extends RefCounted     # was Node: .new() Nodes never get freed, RefCounted cleans itself up

var id: String = "stranger"
var display_name: String = "The Stranger"
var blurb: String = ""

# --- personality (0..1), tuned per day from game_manager
var aggression: float = 0.5        # how eagerly it bets / raises for value
var bluff_rate: float = 0.2        # how often it bets on a weak read
var read_sensitivity: float = 0.4  # how much it trusts its reads of you
var caution: float = 0.15          # how sure it must be before crying LIAR
var learn_rate: float = 0.25       # how fast it updates its opinion of you

# --- memory about the player, learned at every showdown
var player_honesty: float = 0.6    # 0 = always lies, 1 = always truthful

var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_rng.randomize()

func reset_memory() -> void:
	player_honesty = 0.6

# game_manager calls this once the real cards are revealed
func observe_hand(player_told_truth: bool) -> void:
	player_honesty = lerpf(player_honesty, 1.0 if player_told_truth else 0.0, learn_rate)

# ---------------------------------------------------------------- tell phase
# What to tell the player about THEIR card. Returns a card id (0-25).
func choose_tell(their_card_id: int, lie_chance: float) -> int:
	var their_rank := (their_card_id % 13) + 2
	var strength := float(their_rank - 2) / 12.0
	# their strong card is dangerous to me -> lying about it is worth more
	var p_lie := clampf(lie_chance * (0.6 + strength * 0.8), 0.0, 0.95)
	if _rng.randf() >= p_lie:
		return their_card_id
	var lo := 2
	var hi := 14
	if _rng.randf() < 0.75:            # mostly lie in the direction that hurts them
		if strength >= 0.5:
			hi = 7                     # strong card -> "it's weak" -> they fold
		else:
			lo = 9                     # weak card -> "it's strong" -> they bet into me
	var rank := their_rank
	while rank == their_rank:
		rank = _rng.randi_range(lo, hi)
	return _rng.randi_range(0, 1) * 13 + (rank - 2)

# ---------------------------------------------------------------- betting
func decide(v: Dictionary) -> Action.Type:
	var legal: Array = v["legal"]
	var their_rank: int = v["their_rank"]
	var told_rank: int = v["told_rank"]
	var pot: int = v["pot"]
	var to_call: int = v["to_call"]
	var penalty: int = v["lie_penalty"]
	var aggr: float = v["player_aggression"]

	var trust := player_honesty
	var win := _win_prob(their_rank, told_rank, trust)
	# they can see my real card: pushing hard hints mine is weak
	win = clampf(win - (aggr - 0.3) * read_sensitivity * 0.3, 0.02, 0.98)

	# how strong do THEY think their card is? that's what I told them
	var their_belief := float(int(v["my_tell_rank"]) - 2) / 12.0
	var fold_equity := 1.0 - their_belief     # weak belief -> they fold easily

	if Action.Type.LIAR in legal and _wants_liar(trust, win, pot, penalty):
		return Action.Type.LIAR
	if to_call > 0:
		return _facing_bet(legal, win, trust, pot, to_call, penalty, fold_equity)
	return _open(legal, win, fold_equity)

func _wants_liar(trust: float, win: float, pot: int, penalty: int) -> bool:
	var q := clampf(1.0 - trust + _rng.randf_range(-0.08, 0.08), 0.0, 1.0)   # chance they lied
	var stake := float(pot + penalty)
	var accuse_ev := (2.0 * q - 1.0) * stake            # right: +stake, wrong: -stake
	var play_ev := (2.0 * win - 1.0) * float(pot)       # just playing the hand out
	var margin := caution * stake * (1.0 - read_sensitivity * 0.5)
	return accuse_ev > play_ev + margin

func _facing_bet(legal: Array, win: float, trust: float, pot: int, to_call: int,
		penalty: int, fold_equity: float) -> Action.Type:
	var call_ev := win * float(pot) - (1.0 - win) * float(to_call)
	var fold_ev := -(1.0 - trust) * float(penalty)      # folding to a lie costs extra
	var bluffing := _rng.randf() < bluff_rate * fold_equity * 2.0
	var raise_at := 0.68 - aggression * 0.15

	if win > 0.88 and Action.Type.ALLIN in legal and _rng.randf() < aggression:
		return Action.Type.ALLIN
	if win >= raise_at or bluffing:
		if Action.Type.RAISE in legal: return Action.Type.RAISE
		if Action.Type.ALLIN in legal and win >= raise_at: return Action.Type.ALLIN
	if call_ev >= fold_ev:
		return Action.Type.CALL
	return Action.Type.FOLD

func _open(legal: Array, win: float, fold_equity: float) -> Action.Type:
	var bet_at := 0.58 - aggression * 0.2
	var bluffing := _rng.randf() < bluff_rate * fold_equity * 2.0

	if win > 0.9 and Action.Type.ALLIN in legal and _rng.randf() < aggression * 0.5:
		return Action.Type.ALLIN
	if win >= bet_at or bluffing:
		if Action.Type.RAISE in legal: return Action.Type.RAISE
		if Action.Type.ALLIN in legal: return Action.Type.ALLIN   # too short for a full raise
	return Action.Type.CHECK

# ---------------------------------------------------------------- math
static func _beats(mine: int, theirs: int) -> float:
	if mine > theirs: return 1.0
	if mine == theirs: return 0.5
	return 0.0

# P(my hidden card beats theirs), given what I was told and how much I trust it
static func _win_prob(their_rank: int, told_rank: int, trust: float) -> float:
	var if_true := _beats(told_rank, their_rank)
	var if_lie := 0.0                          # a lie means my card is anything but told_rank
	for r in range(2, 15):
		if r != told_rank:
			if_lie += _beats(r, their_rank)
	if_lie /= 12.0
	return trust * if_true + (1.0 - trust) * if_lie
