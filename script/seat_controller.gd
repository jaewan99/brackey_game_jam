class_name SeatController
extends RefCounted

# Answers with an Action. May return instantly (AI) or suspend until a
# click (human) / a packet (remote). Callers always `await` it.
func request_action(_view: Dictionary) -> Action.Type:
	push_error("request_action not implemented")
	return Action.Type.FOLD
