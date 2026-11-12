extends RichTextLabel

const VOICE_DIR := "res://audio/dealer/"
const VOICE_DB := -8.0
# shown as text but not spoken (routine lines get tiring fast). Edit freely.
const TEXT_ONLY := []

const LINES := {
	"day_1": ["Day one. Sit down.", "Welcome. Try to last."],
	"day_next": ["Day %d. You are still here.", "Day %d. A new face for you."],
	"opponent_enter": ["Your opponent has arrived.", "Someone wants your chips."],
	"shuffle": ["Fresh deck.", "Shuffling."],
	"deal": ["Cards are out.", "One card each. Do not look."],
	"tell": ["Tell them what you see.", "Truth or lie. Choose."],
	"player_check": ["You check."],
	"player_raise": ["You raise %d.", "You push %d forward."],
	"player_call": ["You call."],
	"player_allin": ["You are all in.", "Everything you have. Noted."],
	"player_fold": ["You fold."],
	"player_liar": ["You call them a liar."],
	"opp_check": ["They check."],
	"opp_raise": ["They raise %d.", "They want %d more."],
	"opp_call": ["They call."],
	"opp_allin": ["They are all in.", "They bet it all."],
	"opp_fold": ["They fold."],
	"opp_liar": ["They call you a liar."],
	"win_hand": ["The pot is yours.", "You take it."],
	"lose_hand": ["The pot is theirs.", "You lose this one."],
	"tie": ["A tie. The pot stays.", "Same rank. Nobody wins."],
	"fold_fooled": ["They lied. You believed it. Pay.", "You folded to a lie. That costs extra."],
	"liar_right": ["They lied. You were right.", "Caught. They pay."],
	"liar_wrong": ["They told the truth. You pay.", "Wrong call. That costs you."],
	"caught_lying": ["You lied. They knew. Pay.", "Caught lying. Hand it over."],
	"lie_worked": ["They believed you. Good.", "Your lie worked. They pay."],
	"false_accused": ["You told the truth. They pay.", "They were wrong about you."],
	"deathmatch": ["No chips left. Cards decide.", "Deathmatch. High card lives."],
	"deathmatch_tie": ["Again.", "Same rank. Again."],
	"day_survived": ["They are out. You live.", "One more day for you."],
	"dead": ["You are out of chips.", "That is the end of you."],
	"they_say": [
		"They say you hold the %s. I would not trust them.",
		"They say you hold the %s. They might be lying.",
		"They say you hold the %s. Believe it if you like.",
	],
	"you_say": ["You tell them they hold the %s.", "You say: you hold the %s."],
}

var _line := ""                 # current dealer line ("" once it has expired)
var _hinting := false           # a button hint is covering the dealer line
var _timer: Tween
var _alpha: Tween
var _voice: AudioStreamPlayer
var _voice_end := 0             # ticks (ms) when the current voice line finishes

func _ready() -> void:
	text = ""
	modulate.a = 0.0

# dealer line. n fills the %d in lines that have one (day number, raise size).
func say(key: String, n = -1, voiced := true) -> void:    # n: a number or a word

	var variants: Array = LINES.get(key, [])
	if variants.is_empty():
		push_warning("Caption: unknown line '%s'" % key)
		return
	var i := randi() % variants.size()
	var line: String = variants[i]
	var file := "%s_%d" % [key, i + 1]
	if line.contains("%"):
		line = line % [n]
		file += "_n%s" % str(n)
	_line = "DEALER:  " + line

	var hold := 2.5
	Music.fade_out(_voice, 0.1)                     # a new line cuts the old voice
	_voice = null
	var path := VOICE_DIR + file + ".wav"
	_voice_end = 0
	if voiced and key not in TEXT_ONLY and ResourceLoader.exists(path):
		var stream: AudioStream = load(path)
		_voice = Music.play_sfx(stream, VOICE_DB)
		_voice_end = Time.get_ticks_msec() + int(stream.get_length() * 1000.0)
		hold = maxf(hold, stream.get_length() + 0.8)

	if not _hinting:
		_show(_line)
	if _timer: _timer.kill()
	_timer = create_tween()
	_timer.tween_interval(hold)
	_timer.tween_callback(_expire)

# button hover text: covers the dealer line while the mouse is on the button
func hint(t: String) -> void:
	if t == "":
		return
	_hinting = true
	_show(t)

func clear_hint() -> void:
	if not _hinting:
		return
	_hinting = false
	if _line != "":
		_show(_line)
	else:
		_fade_out()

# wipe everything: used on death and between days
func clear_text() -> void:
	_voice_end = 0
	if _timer: _timer.kill()
	if _alpha: _alpha.kill()
	Music.fade_out(_voice, 0.2)
	_voice = null
	_line = ""
	_hinting = false
	text = ""
	modulate.a = 0.0

func _show(t: String) -> void:
	if _alpha: _alpha.kill()
	text = "[center]%s[/center]" % t
	modulate.a = 1.0

func _expire() -> void:
	_line = ""
	if not _hinting:
		_fade_out()

func _fade_out() -> void:
	if _alpha: _alpha.kill()
	_alpha = create_tween()
	_alpha.tween_property(self, "modulate:a", 0.0, 0.4)

# wait until the dealer has finished the current line (returns at once if silent)
func wait_voice(extra := 0.25) -> void:
	var left := (_voice_end - Time.get_ticks_msec()) / 1000.0
	if left > 0.0:
		await get_tree().create_timer(left + extra).timeout
		
