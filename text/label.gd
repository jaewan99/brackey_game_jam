extends Button

@export var bob_amplitude: float = 4.0
@export var bob_speed: float = 4.0
@onready var label: Label = $Label
var mat: ShaderMaterial
@export var is_hoverable: bool = true

var game_manager: Node

# for hovering effect
var base_y: float
var is_hovering: bool = false


func _ready() -> void:
	label.text = text
	text = ""
	focus_mode = Control.FOCUS_NONE
	mat = label.material.duplicate()
	label.material = mat
	base_y = position.y
	game_manager = get_tree().current_scene
	pressed.connect(_handle_input)

func _process(_delta: float) -> void:
	if is_hovering:
		position.y =  base_y + sin(Time.get_ticks_msec() / 1000.0 * bob_speed) * bob_amplitude
	else:
		position.y = base_y
	

func _on_mouse_entered() -> void:
	if not is_hoverable:
		return
	is_hovering = true
	var tween = create_tween()
	tween.tween_method(_set_highlight, mat.get_shader_parameter("highlight_strength"), 0.7, 0.15)

func _on_mouse_exited() -> void:
	is_hovering = false
	var tween = create_tween()
	tween.tween_method(_set_highlight, mat.get_shader_parameter("highlight_strength"),0.0,0.25)

func _set_highlight(value: float) -> void:
	mat.set_shader_parameter("highlight_strength", value)



func _handle_input() -> void:
	disabled = true
	match label.text:
		"START":
			await game_manager.start_game()
		"SETTINGS":
			print("open settings-label.gd")
		# tell phase
		"TRUTH":
			await game_manager.tell_truth()
		"LIE":
			await game_manager.tell_lie()
		# deal phase
		"CHECK":
			await game_manager.player_controller.submit(Action.Type.CHECK)
		"RAISE":
			await game_manager.player_controller.submit(Action.Type.RAISE)
		"CALL":
			await game_manager.player_controller.submit(Action.Type.CALL)
		"FOLD":
			await game_manager.player_controller.submit(Action.Type.FOLD)
		"LIAR":
			await game_manager.player_controller.submit(Action.Type.LIAR)
		"ALL IN":
			await game_manager.player_controller.submit(Action.Type.ALLIN)
	disabled = false
