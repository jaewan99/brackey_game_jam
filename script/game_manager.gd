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

@onready var deck: Node = %Deck
@onready var ui = %UI

# markers
@onready var marker = $Marker
var card_spawn_point :Vector2
var card_player_point :Vector2
var card_opponent_point :Vector2
var card_opponent_reveal_point :Vector2

var _folded_seat = null
var _liar_seat = null
var _checks_in_row := 0

func _ready() -> void:
	card_spawn_point = marker.get_node("CardSpawnMark").global_position
	card_player_point = marker.get_node("CardPlayerMark").global_position
	card_opponent_point = marker.get_node("CardOpponentMark").global_position
	card_opponent_reveal_point = marker.get_node("CardOpponentRevealMark").global_position
	
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
	await _distribute_starting_chips()
	_setup_controller()
	ANTE = 1
	pot = 0
	set_round()
	
func _distribute_starting_chips() -> void:
	ui.set_visible_custom(ui.UIState.CHIPS)
	player_chips = START_CHIPS
	ui.distribute_starting_chips("PLAYER",player_chips)
	opponent_chips = START_CHIPS
	ui.distribute_starting_chips("OPPONENT", opponent_chips)

func set_round() -> void:
	# choose opponent
	# set the index for the round
	await _ante_phase()
	await _draw_phase()
	await _open_tell_phase()

func _ante_phase() -> void:
	var player_ante = min(player_chips, ANTE)
	var opponent_ante = min(opponent_chips, ANTE)
	player_chips -= player_ante
	opponent_chips -= opponent_ante
	pot += player_ante + opponent_ante
	ui.update_chip_visuals(player_chips, opponent_chips, pot)
	

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
	if randf() < opponent_lie_chance:
		opponent_tell = deck.get_random_card_excluding(player_card_number)
	else:
		opponent_tell = player_card_number
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
		ui.update_action_visibility(true, to_call, player_chips, opponent_chips, BET_UNIT)
		var ctrl = player_controller if seat == Turn.PLAYER else opponent_controller
		var action = await ctrl.request_action(_build_view(seat))
		apply_action(seat, action)
		if _bet_over(action):
			break
		seat = Turn.OPPONENT if seat == Turn.PLAYER else Turn.PLAYER
		
func apply_action(seat: Turn, action: Action.Type) -> void:
	var is_player := seat == Turn.PLAYER
	match action:
		Action.Type.FOLD:
			_folded_seat = seat
		Action.Type.CHECK:
			_checks_in_row += 1
		Action.Type.CALL:
			_commit(is_player, to_call)
			to_call = 0
		Action.Type.RAISE:
			_commit(is_player, to_call + BET_UNIT)
			to_call = BET_UNIT
			_checks_in_row = 0
		Action.Type.ALLIN:
			var stack := player_chips if is_player else opponent_chips
			_commit(is_player, stack)
			to_call = maxi(0, stack - to_call)
			_checks_in_row = 0
		Action.Type.LIAR:
			_liar_seat = seat
	ui.update_chip_visuals(player_chips,opponent_chips,pot)

func _commit(is_player: bool, amount:int) -> void:
	if is_player:
		amount = mini(player_chips, amount); player_chips -= amount
	else:
		amount = mini(opponent_chips, amount); opponent_chips -= amount
	pot += amount
#------------------------------------------------- open phase
func _open_phase() -> void:
	ui.set_state(ui.UIState.NONE)
	
	# reveal the player's OWN real card
	await player_card.reveal_to_forehead(card_player_point, 
		player_card.TransformPreset.PLAYERREVEAL,
		deck.get_card_texture_path(player_card_number))
	match _resolve_winner():
		Turn.PLAYER:
			player_chips += pot
			pot = 0
			print("player wins")
		Turn.OPPONENT:
			opponent_chips += pot
			pot = 0
			print("opponent wins")
		_:
			print("Draw")
	ui.update_chip_visuals(player_chips, opponent_chips, pot)
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
	#print("resolve",p_rank, o_rank)
	if p_rank > o_rank:
		return Turn.PLAYER
	if o_rank > p_rank:
		return Turn.OPPONENT
	return null   # equal rank → tie

func _cleanup_round() -> void:
	if is_instance_valid(player_card):
		player_card.queue_free()
	if is_instance_valid(opponent_card):
		opponent_card.queue_free()

func _next_round() -> void:
	if player_chips <= 0 or opponent_chips <= 0:
		print("Game over")            # TODO: real end-game / results screen
		return
	set_round()   # ante + draw + tell + deal again; pot persists so carryover work

# --- aux
	
# -- only what a seat is allowed to know (this is your serialization boundary) ---
func _build_view(seat: Turn) -> Dictionary:
	var i_am_player := seat == Turn.PLAYER
	return {
		# the card THIS seat can see = the *other* player's real card
		"player_card": deck.get_rank(player_card_number if not i_am_player else opponent_card_number),
		"pot": pot,
		"to_call": to_call,
		"ai_chips": opponent_chips if not i_am_player else player_chips,
		"player_aggression": 0.0,   # TODO: derive from betting history
		"bet_unit": BET_UNIT,
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
