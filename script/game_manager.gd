extends Node2D

# the ACTUAL number of the card (from 0-25)
var player_card_number := 0
var opponent_card_number := 0
# the card.tsnc
var player_card: Sprite2D
var opponent_card: Sprite2D
# tell phase // what the player tells the opponent about opponent_card and vice versa
var player_tell := -1 
var opponent_tell := -1
var opponent_lie_chance := 0.5
# Chips
const START_CHIPS := 30
var ANTE := 1
var player_chips:= START_CHIPS
var opponent_chips:= START_CHIPS
var pot := 0
var BET_UNIT := 3
var to_call := 0
enum Turn {PLAYER, OPPONENT}
var current_turn: Turn= Turn.PLAYER

var day := 1
const SAVE_PATH := "user://save.cfg"
var best_day := 1

@onready var deck: Node = %Deck
@onready var ui = %UI
var shake_target: Node          # assigned from game_manager at runtime
# markers
@onready var marker = $Marker
var card_spawn_point :Vector2
var card_player_point :Vector2
var card_opponent_point :Vector2
var card_opponent_reveal_point :Vector2

var _folded_seat = null
var _liar_seat = null
var _checks_in_row := 0


const LIE_PENALTY := 6
var player_aggression := 0.3

const DAY_SUBTITLES := [
	"PRIDE",
	"ENVY",
	"WRATH",
	"SLOTH",
	"GREED",
	"GLUTTONY",
	"LUST",
]


func _ready() -> void:
	card_spawn_point = marker.get_node("CardSpawnMark").global_position
	card_player_point = marker.get_node("CardPlayerMark").global_position
	card_opponent_point = marker.get_node("CardOpponentMark").global_position
	card_opponent_reveal_point = marker.get_node("CardOpponentRevealMark").global_position
	ScreenFx.shake_target = $Camera2D
	ScreenFx.light_target = $PointLight2D
	_load_best_day()

# --- set up-----
var opponent_controller = SeatController
var player_controller = SeatController

func _setup_controller() -> void:
	var brain := AIOpponent.new()
	opponent_controller = AIController.new(brain)
	player_controller = HumanController.new()

# --- start game ---
func start_game() -> void:
	ui.set_state(ui.UIState.NONE)
	day = 1
	_setup_controller()
	_begin_match()

func _begin_match() -> void:
	await ScreenFx.day_card(day, DAY_SUBTITLES[day - 1] if day <= DAY_SUBTITLES.size() else "LIMBO")
	ANTE = 1
	pot = 0
	player_aggression = 0.3
	opponent_controller.brain.reset_memory()   # each day is a new stranger
	_apply_day_difficulty()
	await _distribute_starting_chips()
	set_round()
	
	
func _distribute_starting_chips() -> void:
	ui.set_visible_custom(ui.UIState.CHIPS)
	player_chips = START_CHIPS
	ui.player_coin.set_amount(player_chips)
	opponent_chips = START_CHIPS
	ui.opponent_coin.set_amount(opponent_chips)
	ui.pot_coin.set_amount(0)

func set_round() -> void:
	# choose opponent
	# set the index for the round
	_ante_phase()
	await _draw_phase()
	await _open_tell_phase()

var player_ante
var opponent_ante

func _ante_phase() -> void:
	player_ante = min(player_chips, ANTE)
	opponent_ante = min(opponent_chips, ANTE)
	player_chips -= player_ante
	opponent_chips -= opponent_ante
	pot += player_ante + opponent_ante


func _draw_phase() -> void:
	# get a card(int) from the deck
	player_card_number = deck.draw_card()
	opponent_card_number = deck.draw_card()
	
	# create card
	player_card = deck.spawn_card_at_marker(card_spawn_point, player_card_number, true)
	opponent_card = deck.spawn_card_at_marker(card_spawn_point, opponent_card_number, false)
	
	# move cards in front of the players
	await player_card.send_card_to(card_player_point, player_card.TransformPreset.PLAYER)
	await opponent_card.send_card_to(card_opponent_point, player_card.TransformPreset.OPPONENT)
		
	# reveal the cards in their foreheads
	await player_card.send_card_to(card_player_point, player_card.TransformPreset.PLAYERREVEAL)
	await opponent_card.reveal_to_forehead(card_opponent_reveal_point, player_card.TransformPreset.OPPONENTREVEAL,deck.get_card_texture_path(opponent_card_number))
	
	# players pay for the start bet coins
	await ui.send_chips(ui.player_coin, ui.pot_coin, player_ante)
	await ui.send_chips(ui.opponent_coin, ui.pot_coin, opponent_ante)
# -------------------------- tell phase -----------------------------------------
func _open_tell_phase() -> void:
	ui.set_state(ui.UIState.TELL)
func tell_truth() -> void:
	player_tell = opponent_card_number
	_opponent_tell()
	_finish_tell_phase()
func tell_lie() -> void:
	player_tell = deck.get_random_card_excluding(opponent_card_number)
	_opponent_tell()
	_finish_tell_phase()
func _opponent_tell() -> void:
	opponent_tell = opponent_controller.brain.choose_tell(player_card_number, opponent_lie_chance)
func _finish_tell_phase() -> void:
	ui.set_state(ui.UIState.NONE)
	await player_card.reveal_to_forehead(card_player_point, player_card.TransformPreset.PLAYERREVEAL,deck.get_card_texture_path(opponent_tell))
	_start_deal_phase()

#--------------------------------------deal phase
func _start_deal_phase() -> void:
	ui.set_state(ui.UIState.DEAL)
	current_turn = Turn.PLAYER
	to_call = 0
	_folded_seat = null
	_liar_seat = null
	_checks_in_row = 0
	await _betting_phase()
	_open_phase()

func _betting_phase() -> void:
	var seat := Turn.PLAYER
	while true:
		if _betting_locked(seat):
			break
		var legal := _legal_actions(seat)
		ui.update_action_visibility(seat == Turn.PLAYER, legal)
		var ctrl = player_controller if seat == Turn.PLAYER else opponent_controller
		var action = await ctrl.request_action(_build_view(seat))
		if action not in legal:
			action = _fallback(legal)
		await apply_action(seat, action)
		ScreenFx.set_tension(_pot_tension())
		if _bet_over(action):
			break
		seat = _other(seat)
	ui.update_action_visibility(false, [])
		
func apply_action(seat: Turn, action: Action.Type) -> void:
	var is_player := seat == Turn.PLAYER
	# moving average: recent actions count more, old ones fade
	if is_player and action != Action.Type.LIAR:
		var hit := 1.0 if action == Action.Type.RAISE or action == Action.Type.ALLIN else 0.0
		player_aggression = lerpf(player_aggression, hit, 0.25)
	match action:
		Action.Type.FOLD:
			_folded_seat = seat
		Action.Type.CHECK:
			_checks_in_row += 1
		Action.Type.CALL:
			var owed := to_call
			var moved := _commit(is_player, owed)
			await _send_to_pot(is_player, moved)
			if moved < owed:                         # short call: return the uncalled part
				await _refund(not is_player, owed - moved)
			to_call = 0
		Action.Type.RAISE, Action.Type.ALLIN:
			var owed := to_call
			var want: int = owed + BET_UNIT if action == Action.Type.RAISE else _chips_of(seat)
			want = mini(want, owed + _chips_of(_other(seat)))   # never bet more than they can match
			var moved := _commit(is_player, want)
			await _send_to_pot(is_player, moved)
			_checks_in_row = 0
			if moved <= owed:                        # couldn't even cover it -> it's a short call
				await _refund(not is_player, owed - moved)
				to_call = 0
			else:
				to_call = moved - owed               # what the other side must now match
		Action.Type.LIAR:
			_liar_seat = seat

func _commit(is_player: bool, amount:int) -> int:
	if is_player:
		amount = mini(player_chips, amount); player_chips -= amount
	else:
		amount = mini(opponent_chips, amount); opponent_chips -= amount
	pot += amount
	return amount
#------------------------------------------------- open phase
func _open_phase() -> void:
	ScreenFx.set_tension(0.0)
	ui.set_state(ui.UIState.NONE)
	
	# reveal the player's OWN real card
	await player_card.reveal_to_forehead(card_player_point, 
		player_card.TransformPreset.PLAYERREVEAL,
		deck.get_card_texture_path(player_card_number))
	ScreenFx.shake(8.0, 0.2)
	opponent_controller.brain.observe_hand(not _seat_lied(Turn.PLAYER)) # learns the player hand
	_pay_pot(_resolve_winner())            # no await: starts flying
	await _settle_lie_penalty()            # penalty flies at the same time
	await get_tree().create_timer(0.3).timeout   # let the pot finish landing
	await _cleanup_round()
	_next_round()

# returns Turn.PLAYER / Turn.OPPONENT, or null on a tie (carry pot)
func _resolve_winner():
	# LIAR call
	if _liar_seat != null:
		var accused = Turn.OPPONENT if _liar_seat == Turn.PLAYER else Turn.PLAYER
		return _liar_seat if _seat_lied(accused) else accused
	# a fold ends the hand with no showdown
	if _folded_seat == Turn.PLAYER:
		return Turn.OPPONENT
	if _folded_seat == Turn.OPPONENT:
		return Turn.PLAYER
	# showdown: compare ranks only (suits don't break ties)
	var p_rank :int = deck.get_rank(player_card_number)
	var o_rank :int = deck.get_rank(opponent_card_number)
	if p_rank > o_rank:
		return Turn.PLAYER
	if o_rank > p_rank:
		return Turn.OPPONENT
	return null   # equal rank → tie

func _cleanup_round() -> void:
	if is_instance_valid(player_card):
		await player_card.burn()
	if is_instance_valid(opponent_card):
		opponent_card.burn()
	await get_tree().create_timer(0.6).timeout

func _next_round() -> void:
	# tie with someone broke -> settle the pot with a deathmatch first
	if pot > 0 and (player_chips <= 0 or opponent_chips <= 0):
		await _deathmatch()
	if player_chips <= 0:
		_end_run()
		return
	if opponent_chips <= 0:
		await _advance_day()
		return
	set_round()

# --- aux
func _end_run() -> void:
	ScreenFx.blood_flash(0.85, Color("8a0000"))  # red loss
	await ScreenFx.sack_drop()
	await _reset_game_and_return_to_main()
	await ScreenFx.sack_clear(0.8)

func _advance_day() -> void:
	day += 1
	_record_day()
	ScreenFx.blood_flash(0.6, Color("d9b45c"))   # gold "you survived" flash
	await ScreenFx.blink(2)
	await get_tree().create_timer(1.0).timeout   # let the eyes settle before the day card
	await _begin_match()

func _send_to_pot(is_player: bool, amount: int) -> void:
	if amount <= 0:
		return
	var from = ui.player_coin if is_player else ui.opponent_coin
	await ui.send_chips(from, ui.pot_coin, amount)
	
# -- only what a seat is allowed to know (this is your serialization boundary) ---
func _build_view(seat: Turn) -> Dictionary:
	var me_player := seat == Turn.PLAYER
	var their_card := opponent_card_number if me_player else player_card_number
	var told_me := opponent_tell if me_player else player_tell   # what I was told about MY card
	var i_told := player_tell if me_player else opponent_tell    # what I told THEM
	return {
		"their_rank": deck.get_rank(their_card),
		"told_rank": deck.get_rank(told_me),
		"my_tell_rank": deck.get_rank(i_told),
		"pot": pot,
		"to_call": to_call,
		"my_chips": _chips_of(seat),
		"their_chips": _chips_of(_other(seat)),
		"bet_unit": BET_UNIT,
		"lie_penalty": LIE_PENALTY,
		"player_aggression": player_aggression,
		"legal": _legal_actions(seat),
	}
func _bet_over(action: Action.Type) -> bool:
	match action:
		Action.Type.FOLD, Action.Type.CALL, Action.Type.LIAR:
			return true
		Action.Type.CHECK:
			return _checks_in_row >= 2
	return false

func _seat_lied(teller: Turn) -> bool:
	if teller == Turn.PLAYER:
		return player_tell != opponent_card_number
	else:
		return opponent_tell != player_card_number

func _pot_tension() -> float:
	var total := player_chips + opponent_chips + pot
	return 0.0 if total <= 0 else float(pot) / float(total)
	
func _apply_day_difficulty() -> void:
	# later days: lies more, reads you better, learns faster. Tune freely.
	var b: AIOpponent = opponent_controller.brain
	opponent_lie_chance = clampf(0.3 + day * 0.03, 0.0, 0.7)
	b.aggression       = clampf(0.4 + day * 0.03, 0.0, 0.8)
	b.bluff_rate       = clampf(0.15 + day * 0.02, 0.0, 0.4)
	b.read_sensitivity = clampf(0.3 + day * 0.05, 0.0, 0.9)
	b.learn_rate       = clampf(0.15 + day * 0.03, 0.0, 0.5)
	b.caution          = clampf(0.25 - day * 0.02, 0.05, 0.25)
# -------------

func _load_best_day() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_day = int(cfg.get_value("progress", "best_day", 1))

func _save_best_day() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)                               # keep any other saved values
	cfg.set_value("progress", "best_day", best_day)
	cfg.save(SAVE_PATH)

func _record_day() -> void:
	if day > best_day:
		best_day = day
		_save_best_day()

func _reset_game_and_return_to_main() -> void:
	ScreenFx.set_tension(0.0)              # kill the heartbeat
	ui.chips_ui.visible = false
	pot = 0
	player_chips = START_CHIPS
	opponent_chips = START_CHIPS
	ui.player_coin.set_amount(0)
	ui.opponent_coin.set_amount(0)
	ui.pot_coin.set_amount(0)
	if is_instance_valid(player_card): player_card.queue_free()
	if is_instance_valid(opponent_card): opponent_card.queue_free()
	deck._build_deck()                     # fresh shuffled deck for the next run
	player_tell = -1
	opponent_tell = -1
	# optional "proper ending" card: shown over the sack before returning
	await ScreenFx.day_card(day, "YOU DID NOT SURVIVE   ·   BEST: DAY %d" % best_day, 2.0, false)
	day = 1
	ui.set_state(ui.UIState.MAIN_MENU)

# ----------------------- action decision - for the betting phase
func _other(seat: Turn) -> Turn:
	return Turn.OPPONENT if seat == Turn.PLAYER else Turn.PLAYER

func _chips_of(seat: Turn) -> int:
	return player_chips if seat == Turn.PLAYER else opponent_chips

# the ONE place that knows what a seat may do right now
func _legal_actions(seat: Turn) -> Array:
	var me := _chips_of(seat)
	var them := _chips_of(_other(seat))
	var acts := [Action.Type.FOLD, Action.Type.LIAR]
	if to_call == 0:
		acts.append(Action.Type.CHECK)
	else:
		acts.append(Action.Type.CALL)          # short call allowed (calls all-in)
	# raising only makes sense if the other side can still answer it
	if them > 0 and me > to_call:
		if me >= to_call + BET_UNIT:
			acts.append(Action.Type.RAISE)
		acts.append(Action.Type.ALLIN)
	return acts

# nothing left to decide: I'm all in, or they're all in and I've matched
func _betting_locked(seat: Turn) -> bool:
	if _chips_of(seat) <= 0:
		return true
	return _chips_of(_other(seat)) <= 0 and to_call == 0

# if the AI picks something illegal, take the safest legal option
func _fallback(legal: Array) -> Action.Type:
	if Action.Type.CHECK in legal: return Action.Type.CHECK
	if Action.Type.CALL in legal: return Action.Type.CALL
	return Action.Type.FOLD
	
# give back chips the other side couldn't match
func _refund(to_player: bool, amount: int) -> void:
	if amount <= 0:
		return
	pot -= amount
	if to_player:
		player_chips += amount
	else:
		opponent_chips += amount
	await ui.send_chips(ui.pot_coin, ui.player_coin if to_player else ui.opponent_coin, amount)

# function for the lie detection
# extra chips on top of the pot for whoever got fooled / caught / falsely accused
func _settle_lie_penalty() -> void:
	var payer = null
	if _folded_seat != null and _seat_lied(_other(_folded_seat)):
		payer = _folded_seat                                   # fooled into folding
	elif _liar_seat != null:
		var accused := _other(_liar_seat)
		payer = accused if _seat_lied(accused) else _liar_seat  # caught / false accusation
	if payer == null:
		return
	var amount := mini(LIE_PENALTY, _chips_of(payer))
	if amount <= 0:
		return
	var payer_is_player: bool = payer == Turn.PLAYER
	if payer_is_player:
		player_chips -= amount
		opponent_chips += amount
	else:
		opponent_chips -= amount
		player_chips += amount
	ScreenFx.shake(6.0, 0.15)
	await ui.send_chips(
		ui.player_coin if payer_is_player else ui.opponent_coin,
		ui.opponent_coin if payer_is_player else ui.player_coin,
		amount)
		
# tie at showdown but someone is broke -> nobody can ante again, so settle it now:
# flip one card each, face-up, until the ranks differ. Winner takes the pot.
func _deathmatch() -> void:
	ScreenFx.set_tension(1.0)
	while true:
		player_card_number = deck.draw_card()      # deck rebuilds itself when empty
		opponent_card_number = deck.draw_card()

		player_card = deck.spawn_card_at_marker(card_spawn_point, player_card_number, true)
		opponent_card = deck.spawn_card_at_marker(card_spawn_point, opponent_card_number, false)
		await player_card.send_card_to(card_player_point, player_card.TransformPreset.PLAYER)
		await opponent_card.send_card_to(card_opponent_point, player_card.TransformPreset.OPPONENT)

		# no tell phase: both real cards go face-up straight away
		await opponent_card.reveal_to_forehead(card_opponent_reveal_point,
			player_card.TransformPreset.OPPONENTREVEAL,
			deck.get_card_texture_path(opponent_card_number))
		await player_card.reveal_to_forehead(card_player_point,
			player_card.TransformPreset.PLAYERREVEAL,
			deck.get_card_texture_path(player_card_number), false)
		ScreenFx.shake(12.0, 0.25)

		var p_rank: int = deck.get_rank(player_card_number)
		var o_rank: int = deck.get_rank(opponent_card_number)
		if p_rank == o_rank:
			await _pay_pot(null)                   # grey flash, pot stays, go again
			await _cleanup_round()
			continue
		await _pay_pot(Turn.PLAYER if p_rank > o_rank else Turn.OPPONENT)
		await _cleanup_round()
		ScreenFx.set_tension(0.0)
		return
		
func _pay_pot(winner) -> void:
	var amount := pot
	match winner:
		Turn.PLAYER:
			ScreenFx.blood_flash(0.6, Color("557a30ff"))
			pot = 0
			player_chips += amount
			await ui.send_chips(ui.pot_coin, ui.player_coin, amount)
			print("player wins")
		Turn.OPPONENT:
			ScreenFx.blood_flash(0.85, Color("8a0000"))
			pot = 0
			opponent_chips += amount
			await ui.send_chips(ui.pot_coin, ui.opponent_coin, amount)
			print("opponent wins")
		_:
			ScreenFx.blood_flash(0.3, Color("8a8378"))   # tie: pot carries
			print("Draw")
