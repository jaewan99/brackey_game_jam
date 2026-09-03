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

func _ready() -> void:
	card_spawn_point = marker.get_node("CardSpawnMark").global_position
	card_player_point = marker.get_node("CardPlayerMark").global_position
	card_opponent_point = marker.get_node("CardOpponentMark").global_position
	card_opponent_reveal_point = marker.get_node("CardOpponentRevealMark").global_position
	
func start_game() -> void:
	ui.set_state(ui.UIState.NONE)
	await _distribute_starting_chips()
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
	player_card = deck.spawn_card_at_marker(card_spawn_point, player_card_number)
	opponent_card = deck.spawn_card_at_marker(card_spawn_point, opponent_card_number)
	
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
	print("Player told opponent: ", deck.get_rank(player_tell))
	#print("My card: ", deck.get_rank(player_card_number))
	ui.set_state(ui.UIState.NONE)
	print("Opponent told player: ", deck.get_rank(opponent_tell))
	await player_card.reveal_to_forehead(card_player_point, player_card.TransformPreset.PLAYERREVEAL,deck.get_card_texture_path(opponent_tell))
	ui.set_visible_custom(ui.UIState.QUESTIONMARK)
	_start_deal_phase()

#--------------------------------------deal phase
func _start_deal_phase() -> void:
	ui.set_state(ui.UIState.DEAL)
	current_turn = Turn.PLAYER
	to_call = 0
	ui.update_action_visibility(current_turn == Turn.PLAYER, to_call)

func check() -> void:
	print("Player checks.")
	_close_player_turn()

func call_deal() -> void:
	var amount = min(player_chips, to_call)
	player_chips -= amount
	pot += amount
	to_call = 0
	ui.update_chip_visuals(player_chips,null,pot)
	
	_close_player_turn()
	
func raise() -> void:
	var amount = min(player_chips, BET_UNIT)
	player_chips -= amount
	pot += amount
	to_call = amount
	ui.update_chip_visuals(player_chips,null,pot)
	
	_close_player_turn()
	
func fold() -> void:
	# awardpot(opponent)
	# end hand
	_close_player_turn()

func liar() -> void:
	_close_player_turn()

func all_in() -> void:
	var amount = player_chips
	player_chips -= amount
	pot += amount
	to_call = amount
	ui.update_chip_visuals(player_chips,null,pot)
	_close_player_turn()
	

func _close_player_turn() ->void:
	current_turn = Turn.OPPONENT
	ui.update_action_visibility(current_turn == Turn.PLAYER, to_call)
	ai_decision()

#------------------------------------------------- open phase


#------------------------------------------------- ai
func ai_decision()-> void:
#	# close the ui
	# ai decide here
	# reopen the ui
	current_turn = Turn.PLAYER
	ui.update_action_visibility(current_turn == Turn.PLAYER, to_call)
