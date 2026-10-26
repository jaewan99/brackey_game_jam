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

# --- ink background shader ---
@export var shader: Shader
@export var ink_color: Color = Color("12110c")
@export var ink_accent: Color = Color("241f17")
@export var edge_color: Color = Color("d9b45c")          # gold rim
@export_range(-0.5, 0.5) var slant: float = 0.18
@export_range(0.0, 1.0) var roughness: float = 0.45
@export_range(0.0, 0.5) var taper: float = 0.22

# how tightly the ink wraps the text
@export var bg_pad: Vector2 = Vector2(48.0, 26.0)
@export var bg_offset: Vector2 = Vector2.ZERO            # nudge if ink sits high/low

var _bg: ColorRect
var _mat: ShaderMaterial
var _hover := 0.0

# TODO(layout): place character portrait FIRST, then re-tune fan slots, fan_step, bg_pad/bg_offset against its on-screen rect — current spacing is placeholder (1920x1080 base, center x=960).


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
	_mat.shader = shader if shader else preload("res://text/button_shader.gdshader")
	_mat.set_shader_parameter("ink_color", ink_color)
	_mat.set_shader_parameter("ink_accent", ink_accent)
	_mat.set_shader_parameter("edge_color", edge_color)
	_mat.set_shader_parameter("slant", slant)
	_mat.set_shader_parameter("roughness", roughness)
	_mat.set_shader_parameter("taper", taper)
	_mat.set_shader_parameter("seed", float(get_instance_id() % 97))   # unique fray per button

	_bg = ColorRect.new()
	_bg.material = _mat
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE      # clicks pass through to the button
	_bg.show_behind_parent = true                       # draw behind the text
	add_child(_bg)

	resized.connect(_fit_bg)
	label.resized.connect(_fit_bg)                      # re-wrap when the text changes size
	mouse_entered.connect(func(): _to_hover(1.0))
	mouse_exited.connect(func(): _to_hover(0.0))
	_fit_bg()


func _process(_delta: float) -> void:
	if is_hovering:
		position.y = base_y + sin(Time.get_ticks_msec() / 1000.0 * bob_speed) * bob_amplitude
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
	tween.tween_method(_set_highlight, mat.get_shader_parameter("highlight_strength"), 0.0, 0.25)


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


func _fit_bg() -> void:
	var fs: int = label.get_theme_font_size("font_size")
	var font: Font = label.get_theme_font("font")
	var text_size: Vector2 = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)

	var bg_size: Vector2 = text_size + bg_pad * 2.0
	var text_center: Vector2 = label.position + Vector2(text_size.x, float(fs)) * 0.5

	_bg.size = bg_size
	_bg.position = text_center - bg_size * 0.5 + bg_offset
	_mat.set_shader_parameter("size", bg_size)          # keeps shader aspect correct


func _to_hover(target: float) -> void:
	create_tween().tween_method(
		func(v: float):
			_hover = v
			_mat.set_shader_parameter("hover", v),
		_hover, target, 0.15)
