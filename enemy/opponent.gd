class_name Opponent
extends Node2D


@export var walk_frames: Array[Texture2D]
@onready var walk_marks: Array[Node] = $WalkMarks.get_children()

@onready var visual: CanvasGroup = $Visual
@onready var walk: Sprite2D = $Visual/Walk

func _ready() -> void:
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
	
func _fade(node: CanvasItem, to: float, dur: float) -> void:
	var t := create_tween()
	t.tween_property(node, "modulate:a", to, dur)
	await t.finished
