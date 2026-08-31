extends Node2D

@export var chip_texture: Texture2D
@export var chips_per_stack: int = 10   # cap per visual pile
@export var stack_offset: float = 14.0   # vertical gap between chips in one pile
@export var pile_spacing: float = 90.0  # horizontal gap between piles

@onready var count_label: Label = $CoinCount


func set_amount(amount: int) -> void:
	count_label.text = str(amount)
