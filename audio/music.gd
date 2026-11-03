extends Node

var _bgm: AudioStreamPlayer

# bgm
const BGM_MAIN_MENU := preload("res://audio/bgm/main_menu/Night in Venice.mp3")
const BGM_TABLE := preload("res://audio/bgm/Table/Vibing Over Venus.mp3")
# card
const CARD_SLIDE := preload("res://audio/sfx/card/card-slide/card-slide.tres")



func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
# fire and forget. Returns the player in case you want to await it.
func play_sfx(stream: AudioStream, volume_db := 0.0, pitch := 1.0) -> AudioStreamPlayer:
	if stream == null:
		return null
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.bus = "SFX"
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	return p

func play_and_await_sfx(stream: AudioStream, volume_db := 0.0, pitch := 1.0) -> void:
	var p := play_sfx(stream, volume_db, pitch)
	if p:
		await p.finished
		
func play_bgm(stream: AudioStream, fade := 1.5, volume_db := -6.0) -> void:
	if _bgm and _bgm.stream == stream:
		return # already playing this track
	var old := _bgm
	_bgm = AudioStreamPlayer.new()
	_bgm.stream = stream
	_bgm.bus = "BGM"
	_bgm.volume_db = -60.0
	add_child(_bgm)
	_bgm.play()
	create_tween().tween_property(_bgm, "volume_db", volume_db, fade)
	if old:
		var t := create_tween()
		t.tween_property(old, "volume_db", -60.0, fade)
		t.tween_callback(old.queue_free)

func stop_bgm(fade := 1.5) -> void:
	if _bgm:
		var t := create_tween()
		t.tween_property(_bgm, "volume_db", -60.0, fade)
		t.tween_callback(_bgm.queue_free)
		_bgm = null
