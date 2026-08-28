extends Node2D

# the ACTUAL number of the card (from 0-25)
var player_card_number := 0
var opponent_card_number := 0

@onready var anim: Node = %AnimationController
@onready var deck: Node = %Deck
@onready var ui = %UI

# markers
@onready var marker = $Marker

func set_round() -> void:
	ui.set_state(ui.UIState.NONE)
	# choose opponent
	# set the index for the round
	await _draw_phase()

func _draw_phase() -> void:
	# get a card(int) from the deck
	player_card_number = deck.draw_card()
	opponent_card_number = deck.draw_card()
	# create card
	marker.get_node("CardSpawnMark").global_position
	# move cards in front of the players
	
	# reveal the opponent's cards in opponent's forehea
