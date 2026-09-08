class_name HumanController
extends SeatController

signal _chosen(action: Action)

func request_action(_view: Dictionary) -> Action.Type:
	return await _chosen          # suspends until the player clicks

# Button handlers call these:
func submit(action: Action) -> void:
	_chosen.emit(action)
