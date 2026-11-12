extends Control

const SAVE_PATH := "user://save.cfg"            # same file as best_day
const FONT := preload("res://art/fontstyle/EBGaramond/EBGaramond12-Italic.ttf")
# bus name -> label shown to the player
const BUSES := {"Master": "VOLUME", "BGM": "MUSIC", "SFX": "SOUND"}

const BACK_BUTTON := preload("res://text/text.tscn")
const BACK_GAP := 48.0            # space between the last slider and BACK

var _box: VBoxContainer
var _back: Button


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
	
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 26)
	center.add_child(_box)

	_box.add_child(_make_label("SETTINGS", 84, Color("e8d7a0")))

	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	for bus in BUSES:
		var value := float(cfg.get_value("audio", bus, 1.0))
		_apply(bus, value)                       # saved volumes take effect at startup
		_box.add_child(_make_row(bus, value))
	# BACK: the same ink button as the rest of the game; label.gd handles the click
	_back = BACK_BUTTON.instantiate()
	_back.text = "BACK"
	_back.anchor_right = 0.0
	_back.anchor_bottom = 0.0
	add_child(_back)
	visibility_changed.connect(_place_back)
	_place_back()
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

# put BACK centred under the slider column (runs each time the menu is shown)
func _place_back() -> void:
	if not is_visible_in_tree():
		return
	await get_tree().process_frame               # let the column finish its layout first
	_back.size = Vector2(300, 110)
	_back.position = Vector2(
		(size.x - _back.size.x) * 0.5,
		_box.global_position.y - global_position.y + _box.size.y + BACK_GAP)
	_back.base_y = _back.position.y              # label.gd's hover bob rests at this height
