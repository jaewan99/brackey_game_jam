extends Node

# card
const CARD_SLIDE := preload("res://audio/sfx/card/card-slide/card-slide.tres")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
# fire and forget. Returns the player in case you want to await it.
func play(stream: AudioStream, volume_db := 0.0, pitch := 1.0) -> AudioStreamPlayer:
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

func play_and_await(stream: AudioStream, volume_db := 0.0, pitch := 1.0) -> void:
	var p := play(stream, volume_db, pitch)
	if p:
		await p.finished
