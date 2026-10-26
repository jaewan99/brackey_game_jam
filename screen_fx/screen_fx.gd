extends CanvasLayer

var vignette: ColorRect
var shake_target: Node          # set from game_manager: ScreenFx.shake_target = $Camera2D
var _strength := 0.0
var _heart: Tween

@export var heartbeat_min_tension := 0.12     # below this, no pulse at all
var _tension := -1.0

func _ready() -> void:
	layer = 100                 # draw above the game
	vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://screen_fx/screen_vignette.gdshader")   # <-- fix to your real path
	vignette.material = mat
	add_child(vignette)
	_set_strength(0.0)


func _set_strength(v: float) -> void:
	_strength = v
	vignette.material.set_shader_parameter("strength", v)

func blood_flash(intensity := 0.8, color := Color(0.55, 0.0, 0.0)) -> void:
	vignette.material.set_shader_parameter("tint", color)
	create_tween().tween_method(_set_strength, intensity, 0.0, 0.6).set_ease(Tween.EASE_OUT)

func start_heartbeat(color := Color(0.85, 0.85, 0.85), speed := 1.0, intensity := 1.0) -> void:
	stop_heartbeat()
	vignette.material.set_shader_parameter("tint", color)
	var hi := 0.50 * intensity
	var mid := 0.14 * intensity
	var dub := 0.38 * intensity
	var lo := 0.06 * intensity
	_heart = create_tween().set_loops()
	_heart.tween_method(_set_strength, lo,  hi,  0.11 / speed)   # lub
	_heart.tween_method(_set_strength, hi,  mid, 0.16 / speed)
	_heart.tween_method(_set_strength, mid, dub, 0.09 / speed)   # dub
	_heart.tween_method(_set_strength, dub, lo,  0.20 / speed)
	_heart.tween_interval(0.55 / speed)

func set_tension(t: float) -> void:
	t = clamp(t, 0.0, 1.0)
	_tension = t
	if t < heartbeat_min_tension:
		stop_heartbeat()
		return
	var speed := lerpf(0.8, 2.2, t)                 # slow thud -> racing
	var intensity := lerpf(0.5, 1.0, t)             # faint -> strong
	var color := Color(0.6, 0.0, 0.0).lerp(Color(0.95, 0.1, 0.1), t)  # deepens as it rises
	start_heartbeat(color, speed, intensity)
	
func stop_heartbeat() -> void:
	if _heart and _heart.is_running():
		_heart.kill()
	create_tween().tween_method(_set_strength, _strength, 0.0, 0.4)

func shake(amount := 10.0, duration := 0.25) -> void:
	if shake_target == null:
		return
	var t := create_tween()
	var steps := int(duration / 0.02)
	for i in steps:
		var decay := 1.0 - float(i) / float(steps)
		t.tween_property(shake_target, "offset",
			Vector2(randf_range(-amount, amount), randf_range(-amount, amount)) * decay, 0.02)
	t.tween_property(shake_target, "offset", Vector2.ZERO, 0.05)
