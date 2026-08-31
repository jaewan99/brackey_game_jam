extends Label

@export var bob_amplitude: float = 4.0
@export var bob_speed: float = 4.0
@onready var mat: ShaderMaterial = material

var game_manager: Node

# for hovering effect
var base_y: float
var is_hovering: bool = false

# for disable double click
var input_locked: bool = false

func _ready() -> void:
	material = material.duplicate()
	mat = material
	base_y = position.y
	game_manager = get_tree().current_scene

func _process(_delta: float) -> void:
	if is_hovering:
		position.y =  base_y + sin(Time.get_ticks_msec() / 1000.0 * bob_speed) * bob_amplitude
	else:
		position.y = base_y
	
func _on_mouse_entered() -> void:
	is_hovering = true
	var tween = create_tween()
	tween.tween_method(_set_highlight, mat.get_shader_parameter("highlight_strength"),0.7,0.15)

func _on_mouse_exited() -> void:
	is_hovering = false
	var tween = create_tween()
	tween.tween_method(_set_highlight, mat.get_shader_parameter("highlight_strength"),0.0,0.25)

func _set_highlight(value: float) -> void:
	mat.set_shader_parameter("highlight_strength", value)


func _on_gui_input(event: InputEvent) -> void:
	if input_locked:
		return
	if event is InputEventMouse and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_input()

func _handle_input() -> void:
	input_locked = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	match text:
		"START":
			await game_manager.start_game()
		"SETTINGS":
			print("open settings-label.gd")
		"TRUTH":
			await game_manager.tell_truth()
		"LIE":
			await game_manager.tell_lie()
	input_locked = false
	mouse_filter = Control.MOUSE_FILTER_STOP
