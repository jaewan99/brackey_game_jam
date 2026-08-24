class_name AIOpponent
extends Node


var id: String = "stranger"
var display_name: String = "The Stranger"
var blurb: String = ""

var aggression: float = 0.5 # 0..1 how often it bets/raises vs checks/calls
var bluff_rate: float = 0.2 # 0..1 chance to represent the opposite of truth
var read_sensitivity: float = 0.4 # 0..1 how much it reads player aggression as a tell
var fold_floor: float = 0.3 # win-prob below which it lays hands down

var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_rng.randomize()

## Probability the AI's unseen card beats the player's visible card (ties = half).
static func win_prob_vs(player_card:int)-> float:
	var wins := 14 - player_card
	var ties := 1
	return (float(wins) + .5 * float(ties)) / 13.0

func decide(state:Dictionary) -> String:
	var player_card: int = state["player_card"]
	var pot: int = state["pot"]
	var to_call: int = state["to_call"]
	var ai_chips: int = state["ai_chips"]
	var player_aggression: float = state.get("player_aggression, 0.0")
	
	var win_prob := win_prob_vs(player_card)
	# Player betting hard is weak evidence the AI's own card is bad (they can see it).
	win_prob = clampf(win_prob - player_aggression * read_sensitivity * 0.25, 0.02, 0.98)
	
	var bluffing := _rng.randf() < bluff_rate
	
	if to_call > 0:
		return _facing_bet(win_prob, pot, to_call, ai_chips, bluffing)
	return _open(win_prob,ai_chips, bluffing)
	
func _facing_bet(win_prob: float, pot:int, to_call:int, ai_chips:int, bluffing:bool) -> String:
	return "call"
func _open(win_prob:float,ai_chips:int, bluffing:bool):
	return "call"
	
	
	
	
	
	
