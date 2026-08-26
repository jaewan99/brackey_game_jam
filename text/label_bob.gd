extends Label

@export var bob_amplitude: float = 4.0
@export var bob_speed: float = 4.0
@onready var mat: ShaderMaterial = material


var base_y: float
var is_hovering: bool = false

func _ready() -> void:
	material = material.duplicate()
	mat = material
	base_y = position.y
	
func _process(delta: float) -> void:
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
