class_name Opponent
extends Node2D


@export var walk_frames: Array[Texture2D]
@onready var walk_marks: Array[Node] = $WalkMarks.get_children()

@onready var visual: CanvasGroup = $Visual
@onready var walk: Sprite2D = $Visual/Walk
@onready var sit: AnimatedSprite2D = $Visual/Sit

func _ready() -> void:

	sit.visible = false
	walk.visible = false

func enter() -> void:
	walk.visible = true
	for i in walk_frames.size():
		walk.texture = walk_frames[i]
		walk.global_position = walk_marks[i].global_position
		walk.modulate.a = 0.0
		await _fade(walk, 1.0, 0.35)
		await get_tree().create_timer(0.5).timeout
		await _fade(walk, 0.0, 0.35)
	
	walk.visible = false
	sit.animation = "raise"
	sit.frame = 0
	sit.modulate.a = 0.0
	sit.visible = true
	await _fade(sit, 1.0, 0.4)
	
func _fade(node: CanvasItem, to: float, dur: float) -> void:
	var t := create_tween()
	t.tween_property(node, "modulate:a", to, dur)
	await t.finished

func raise_card() -> void:
	sit.frame = 0
	sit.play("raise")
	await sit.animation_finished

func lower_card() -> void:
	sit.play_backwards("raise")
	await sit.animation_finished

func reset() -> void:
	sit.visible = false
	sit.stop()
	sit.frame = 0
	walk.visible = false

func leave() -> void:
	await _fade(sit, 0.0, 0.5)
	reset()
