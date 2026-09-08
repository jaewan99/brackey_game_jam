class_name AIController
extends SeatController

var brain: AIOpponent

func _init(ai: AIOpponent) -> void:
	brain = ai

func request_action(view: Dictionary) -> Action.Type:
	return brain.decide(view)   # instant
