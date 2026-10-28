extends CanvasLayer

var vignette: ColorRect
var shake_target: Node          # set from game_manager: ScreenFx.shake_target = $Camera2D
var _strength := 0.0
var _heart: Tween

@export var heartbeat_min_tension := 0.12     # below this, no pulse at all
var _tension := -1.0

# --- win and lose
var light_target: Node2D        # set from game_manager: ScreenFx.light_target = $PointLight2D

# --- win: eyelid blink ---
var _eye_top: ColorRect
var _eye_bottom: ColorRect
var _flicker: Tween

# --- lose: sack drop ---
var _sack: ColorRect
# --- 

# --- n-day
@export var title_font = preload("res://art/fontstyle/EBGaramond/EBGaramond12-Italic.ttf") # optional: assign a vintage serif .ttf (1930s look)



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
	
	# win and lose
	# eyelids: two black bars that grow toward the center (top + bottom)
	_eye_top = ColorRect.new()
	_eye_top.color = Color.BLACK
	_eye_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eye_top.anchor_left = 0.0; _eye_top.anchor_right = 1.0     # full width
	_eye_top.anchor_top = 0.0;  _eye_top.anchor_bottom = 0.0    # pinned to top edge
	_eye_top.offset_bottom = 0.0                                # starts closed = height 0
	_eye_top.visible = false
	add_child(_eye_top)

	_eye_bottom = ColorRect.new()
	_eye_bottom.color = Color.BLACK
	_eye_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eye_bottom.anchor_left = 0.0; _eye_bottom.anchor_right = 1.0
	_eye_bottom.anchor_top = 1.0;  _eye_bottom.anchor_bottom = 1.0   # pinned to bottom edge
	_eye_bottom.offset_top = 0.0
	_eye_bottom.visible = false
	add_child(_eye_bottom)

	# sack: black panel whose bottom edge sweeps top -> down over the screen
	_sack = ColorRect.new()
	_sack.color = Color.BLACK
	_sack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sack.anchor_left = 0.0; _sack.anchor_right = 1.0
	_sack.anchor_top = 0.0;  _sack.anchor_bottom = 0.0
	_sack.offset_bottom = 0.0
	_sack.visible = false
	add_child(_sack)


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

# WIN: eyes blink a couple of times (waking / adjusting to the light) while
# the hanging light sways. Ends with eyes open.
func blink(times := 2, close_time := 0.12, hold := 0.05, flicker := true) -> void:
	var half := get_viewport().get_visible_rect().size.y * 0.5
	_eye_top.visible = true
	_eye_bottom.visible = true
	if flicker:
		flicker_light()
	var t := create_tween()
	for i in times:
		# close
		t.tween_property(_eye_top, "offset_bottom", half, close_time).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(_eye_bottom, "offset_top", -half, close_time).set_ease(Tween.EASE_IN)
		t.tween_interval(hold)
		# open
		t.tween_property(_eye_top, "offset_bottom", 0.0, close_time).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(_eye_bottom, "offset_top", 0.0, close_time).set_ease(Tween.EASE_OUT)
		t.tween_interval(hold)
	t.tween_callback(func() -> void:
		_eye_top.visible = false
		_eye_bottom.visible = false)
	await t.finished

# Dying-filament flicker: erratic energy stutter — brief near-blackouts,
# weak glows, the odd bright pop. dying=true leaves it dark; false restores it.
func flicker_light(base_energy := 1.0, duration := 1.6, dying := false) -> void:
	if light_target == null:
		return
	if _flicker and _flicker.is_running():
		_flicker.kill()
	_flicker = create_tween()
	var elapsed := 0.0
	while elapsed < duration:
		var r := randf()
		var lvl: float
		if r < 0.35:
			lvl = randf_range(0.0, 0.12) * base_energy   # near-out
		elif r < 0.75:
			lvl = randf_range(0.2, 0.55) * base_energy    # weak glow
		else:
			lvl = randf_range(0.85, 1.2) * base_energy    # bright pop
		var step := randf_range(0.03, 0.11)
		_flicker.tween_property(light_target, "energy", lvl, step)
		elapsed += step
	_flicker.tween_property(light_target, "energy", (0.0 if dying else base_energy), 0.25)
	
# LOSE: a black panel sweeps top -> down, covering vision like a sack pulled
# over the head. Leaves the screen fully covered.
func sack_drop(duration := 0.9, color := Color.BLACK, settle := true) -> void:
	var h := get_viewport().get_visible_rect().size.y
	_sack.color = color
	_sack.offset_bottom = 0.0
	_sack.visible = true
	var t := create_tween()
	t.tween_property(_sack, "offset_bottom", h, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if settle:
		# tiny bob as the sack settles
		t.tween_property(_sack, "offset_bottom", h - 14.0, 0.08)
		t.tween_property(_sack, "offset_bottom", h, 0.10)
	await t.finished

# Call when returning to the menu / starting fresh so the screen is clear again.
func sack_clear() -> void:
	_sack.visible = false
	_sack.offset_bottom = 0.0
	
func day_card(n: int, subtitle := "", hold := 1.4) -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# plain black backdrop again
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("140d08")
	root.add_child(bg)
	
	# grain overlay — added LAST so it grains the backdrop AND the title text
	var grain := ColorRect.new()
	grain.set_anchors_preset(Control.PRESET_FULL_RECT)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gmat := ShaderMaterial.new()
	gmat.shader = preload("res://screen_fx/film_grain.gdshader")
	grain.material = gmat
	root.add_child(grain)
	
	# this layer is what jitters (film weave) — bg underneath doesn't move
	var weave := Control.new()
	weave.set_anchors_preset(Control.PRESET_FULL_RECT)
	weave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(weave)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	weave.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "DAY %d" % n
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("e8d7a0"))
	title.add_theme_font_size_override("font_size", 92)
	if title_font: title.add_theme_font_override("font", title_font)
	vbox.add_child(title)

	if subtitle != "":
		var sub := Label.new()
		sub.text = subtitle
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.add_theme_color_override("font_color", Color("c9b483"))
		sub.add_theme_font_size_override("font_size", 34)
		if title_font: sub.add_theme_font_override("font", title_font)
		vbox.add_child(sub)

	# fade in -> flicker + weave -> fade out
	root.modulate.a = 0.0
	var tin := create_tween()
	tin.tween_property(root, "modulate:a", 1.0, 0.35).set_ease(Tween.EASE_OUT)
	await tin.finished

	var fl := create_tween()
	var elapsed := 0.0
	while elapsed < hold:
		var step := randf_range(0.05, 0.12)
		fl.tween_property(weave, "position:y", randf_range(-1.5, 1.5), step)
		elapsed += step
	await fl.finished

	var tout := create_tween()
	tout.tween_property(root, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN)
	await tout.finished
	root.queue_free()
