extends Sprite2D

@export var card_back_texture: Texture2D
@export var card_face_texture: Texture2D

enum TransformPreset { START, PLAYER, OPPONENT, PLAYERREVEAL, OPPONENTREVEAL}

const TRANSFORM_PRESETS := {
	TransformPreset.START: {
		"scale": Vector2(0.195, 0.26),
		"y_rot": -44.756,
		"x_rot": 29.89,
		"inset": 0.11,
		"target_rotation": 90.0
	},
	TransformPreset.PLAYER: {
		"scale": Vector2(0.335, 0.277),
		"y_rot": 0.0,
		"x_rot": 18.462,
		"inset": 0.0,
		"target_rotation": 0.0
	},
	TransformPreset.OPPONENT: {
		"scale": Vector2(0.22, 0.137),
		"y_rot": 0.0,
		"x_rot": 18.462,
		"inset": 0.0,
		"target_rotation": 0.0
	},
	TransformPreset.PLAYERREVEAL: {
		"scale": Vector2(0.25, 0.25),
		"y_rot": 0.0,
		"x_rot": 0.0,
		"inset": 0.0,
		"target_rotation": 0.0
	},
	TransformPreset.OPPONENTREVEAL: {
		"scale": Vector2(0.15, 0.15),
		"y_rot": 0.0,
		"x_rot": 0.0,
		"inset": 0.0,
		"target_rotation": 0.0
	}
}

func _ready() -> void:
	material = material.duplicate()
	texture = card_back_texture
	
	scale = Vector2(0.195,0.26)
	material.set_shader_parameter("y_rot", -44.756)
	material.set_shader_parameter("x_rot", 29.89)
	material.set_shader_parameter("inset", 0.11)
	rotation_degrees = 90.0

func send_card_to(spawn_point: Vector2, preset: TransformPreset):
	var card_transform_data: Dictionary = TRANSFORM_PRESETS[preset]
	var actual_duration = randf_range(0.8, 1.2)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", spawn_point, actual_duration)
	tween.tween_property(self, "rotation", card_transform_data["target_rotation"], actual_duration)
	tween.tween_property(self, "scale", card_transform_data["scale"], actual_duration)
	material.set_shader_parameter("x_rot", card_transform_data["x_rot"])
	material.set_shader_parameter("y_rot", card_transform_data["y_rot"])
	material.set_shader_parameter("inset", card_transform_data["inset"])
	await tween.finished

func reveal_to_forehead(target_position: Vector2, preset: TransformPreset, card_texture_path:String) -> void:
	var card_transform_data: Dictionary = TRANSFORM_PRESETS[preset]
	var duration = randf_range(0.6, 0.9)
	var flip_point = duration * 0.5  # texture swaps at the midpoint of the whole move

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# move + rotate + shader perspective, same as send_card_to
	tween.tween_property(self, "position", target_position, duration)
	tween.tween_property(self, "rotation", card_transform_data["target_rotation"], duration)
	tween.tween_method(_set_x_rot, material.get_shader_parameter("x_rot"), card_transform_data["x_rot"], duration)
	tween.tween_method(_set_y_rot, material.get_shader_parameter("y_rot"), card_transform_data["y_rot"], duration)
	tween.tween_method(_set_inset, material.get_shader_parameter("inset"), card_transform_data["inset"], duration)

	# flip: scale.x collapses to 0 then expands to target scale.x, texture swaps at the midpoint
	tween.tween_property(self, "scale:y", 0.0, flip_point).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func(): texture = load(card_texture_path))
	tween.chain().tween_property(self, "scale:y", card_transform_data["scale"].y, duration - flip_point).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# scale.x animates normally across the whole duration, independent of the flip's y collapse
	tween.tween_property(self, "scale:x", card_transform_data["scale"].x, duration)
	await tween.finished
	
func _set_x_rot(value: float) -> void:
	material.set_shader_parameter("x_rot", value)

func _set_y_rot(value: float) -> void:
	material.set_shader_parameter("y_rot", value)

func _set_inset(value: float) -> void:
	material.set_shader_parameter("inset", value)
