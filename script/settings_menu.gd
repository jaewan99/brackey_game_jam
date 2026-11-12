extends Control

const SAVE_PATH := "user://save.cfg"            # same file as best_day
const FONT := preload("res://art/fontstyle/EBGaramond/EBGaramond12-Italic.ttf")
# bus name -> label shown to the player
const BUSES := {"Master": "VOLUME", "BGM": "MUSIC", "SFX": "SOUND"}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# dark veil so the table behind doesn't fight the text
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	move_child(dim, 0)                           # behind the BACK button you add in the editor

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 26)
	center.add_child(box)

	box.add_child(_make_label("SETTINGS", 84, Color("e8d7a0")))

	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	for bus in BUSES:
		var value := float(cfg.get_value("audio", bus, 1.0))
		_apply(bus, value)                       # saved volumes take effect at startup
		box.add_child(_make_row(bus, value))

func _make_label(t: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _make_row(bus: String, value: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)

	var name_label := _make_label(BUSES[bus], 40, Color("c9b483"))
	name_label.custom_minimum_size = Vector2(220, 0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(name_label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(460, 36)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(func(v: float): _apply(bus, v))
	slider.drag_ended.connect(func(_changed: bool):
		_save(bus, slider.value)
		Music.play_sfx(Music.BUTTON_CLICK, -4.0, 1.0, 0.05))   # hear the new level
	row.add_child(slider)
	return row

func _apply(bus: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.0001)))
	AudioServer.set_bus_mute(idx, value <= 0.001)

func _save(bus: String, value: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)                          # keep best_day and the other volumes
	cfg.set_value("audio", bus, value)
	cfg.save(SAVE_PATH)
