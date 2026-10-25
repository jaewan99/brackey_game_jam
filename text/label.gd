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
	
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(s, StyleBoxEmpty.new())

	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_mat.set_shader_parameter("base_color", base_color)
	_mat.set_shader_parameter("accent_color", accent_color)
	_mat.set_shader_parameter("edge_color", edge_color)
	_mat.set_shader_parameter("corner_radius", corner_radius)
	_mat.set_shader_parameter("border_width", border_width)

	_bg = ColorRect.new()
	_bg.material = _mat
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE      # clicks pass through to the button
	_bg.show_behind_parent = true                       # draw behind the button's text
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	resized.connect(_sync_size)
	mouse_entered.connect(func(): _to_hover(1.0))
	mouse_exited.connect(func(): _to_hover(0.0))
	_sync_size()

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


@export var shader: Shader
@export var base_color: Color = Color("171f2e")
@export var accent_color: Color = Color("2e6bb8")
@export var edge_color: Color = Color("99d9ff")
@export_range(0.0, 0.5) var corner_radius: float = 0.22
@export_range(0.0, 0.2) var border_width: float = 0.05

var _bg: ColorRect
var _mat: ShaderMaterial
var _hover := 0.0

func _sync_size() -> void:
	_mat.set_shader_parameter("size", size)

func _to_hover(target: float) -> void:
	create_tween().tween_method(
		func(v: float):
			_hover = v
			_mat.set_shader_parameter("hover", v),
		_hover, target, 0.15)
