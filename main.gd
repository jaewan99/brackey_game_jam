extends Control

const START_CHIPS := 30
const ANTE := 1 # the min coin bet
const BET_UNIT := 3

#const MAX_RAISE := 3 # i won't be using this since i think we can raise as much we can

var player_chips := START_CHIPS
var ai_chips := START_CHIPS
var pot := 0
var player_card := 0
var ai_card := 0
var hand_index := 0

var ai: AIOpponent
var turn := "player"
var to_call := 0
#var raises_left := MAX_RAISE
var checks_in_row := 0
var hand_over := true
var player_bets_this_hand := 0
var _last_award_msg := 0


# --- Scene nodes ---
@onready var lbl_ai_name: Label = %AiName
@onready var lbl_ai_chips: Label = %AiChips
@onready var lbl_ai_card: Label = %AiCard
@onready var lbl_pot: Label = %Pot
@onready var lbl_msg: Label = %Msg
@onready var lbl_player_card: Label = %PlayerCard
@onready var lbl_player_chips: Label = %PlayerChips
@onready var btn_check: Button = %Check
@onready var btn_call: Button = %Call
@onready var btn_bet: Button = %Bet
@onready var btn_raise: Button = %Raise
@onready var btn_fold: Button = %Fold
@onready var btn_next: Button = %Next


func _ready() -> void:
	ai = _make_opponent()
	btn_bet.text = "Bet " + str(BET_UNIT)
	btn_raise.text = "Raise " + str(BET_UNIT)
	start_hand()
	
# maybe we can change this to json
func _make_opponent() -> AIOpponent:
	var o := AIOpponent.new()
	o.display_name = "\"Honest\" Ike"
	o.blurb = "Bets what he sees. Mostly."
	o.aggression = .55
	o.bluff_rate = .15
	o.read_sensitivity = .3
	o.fold_floor = .35
	return o
	
# ---------------------------------------------------------------- card display
func _card_text(v: int) -> String:
	match v:
		14: return "A"
		13: return "K"
		12: return "Q"
		11: return "J"
		_: return str(v)

# ---------------------------------------------------------------- hand flow
func start_hand() -> void:
	hand_over = false
	pot = 0
	#raise_left
	checks_in_row = 0
	player_bets_this_hand = 0
	player_card = randi_range(2,14)
	ai_card = randi_range(2,14)
	_put_in("player", ANTE)
	_put_in("ai", ANTE)
	turn = "player" if hand_index % 2 == 0 else "ai"
	to_call = 0
	_disable_player_actions()
	btn_next.visible = false
	_set_msg("New hand. Antes posted")
	_update_ui()
	if turn == "ai":
		_ai_turn()
	else:
		_enable_player_actions()
		
	

func _put_in(who:String, amount:int) ->int:
	var chips := player_chips if who == "player" else ai_chips
	var actual: int = min(chips, amount)
	if who == "player":
		player_chips -= actual
	else:
		ai_chips -= actual
	pot += actual
	return actual
	
func _disable_player_actions() -> void:
	for b in [btn_check, btn_call, btn_bet, btn_raise, btn_fold]:
		b.visible = false
func _enable_player_actions() -> void:
	btn_next.visible = false
	var facing := to_call > 0
	var can_raise := player_chips > to_call
	btn_check.visible = not facing
	btn_bet.visible = not facing and player_chips > 0
	btn_call.visible = facing
	btn_raise.visible = facing and can_raise
	btn_fold.visible = facing
	_set_buttons_enabled(true)
	
func _set_buttons_enabled(on: bool) -> void:
	for b in [btn_check, btn_call, btn_bet, btn_raise, btn_fold]:
		b.disabled = not on
	
func _set_msg(t:String)-> void:
	if lbl_msg:
		lbl_msg.text = t

func _update_ui(reveal_player := false) -> void:
	lbl_ai_name.text = ai.display_name
	lbl_ai_card.text = _card_text(ai_card)
	lbl_player_card.text = _card_text(player_card) if (reveal_player or hand_over) else "?"
	lbl_pot.text = "POT: %d" % pot
	lbl_ai_chips.text = "%s: %d chips" % [ai.display_name, ai_chips]
	lbl_player_chips.text = "You: %d chips" % player_chips
	
func _ai_turn() -> void:
	if hand_over:
		return
	await get_tree().create_timer(.7).timeout
	var state := {
		"player_card" : player_card,
		"pot" : pot,
		"to_call": to_call,
		"bet_unit": BET_UNIT,
		"ai_chips": ai_chips,
		"player_aggression": clampf(float(player_bets_this_hand) / 3.0, 0.0, 1.0)
	}
	var kind := ai.decide(state)
	if to_call > 0 and kind == "check": kind = "call"
	if to_call == 0 and kind == "call": kind = "check"
	if (kind == "bet" or kind == "raise") and (ai_chips <= 0):
		kind = "call" if to_call > 0 else "check"
	var closed := _apply_action("ai", kind)

func _apply_action(who:String, kind:String) -> bool:
	var other := "ai" if who == "player" else "player"
	match kind:
		"fold":
			_award_pot(other, )
