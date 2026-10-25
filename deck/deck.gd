# this deck gd is for the design part

extends Node2D

@export var deck_logic: Node
@onready var count_label = $CardsCount

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	count_label.visible = false
	

func _on_area_2d_mouse_entered() -> void:
	count_label.text = str(deck_logic.deck.size())
	count_label.visible = true



func _on_area_2d_mouse_exited() -> void:
	count_label.visible = false
