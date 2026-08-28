extends Sprite2D

@export var card_back_texture: Texture2D
@export var card_face_texture: Texture2D

var card_transform_data_start := {
	"position": Vector2(1746.38, 733.562),
	"scale": Vector2(0.335, 0.277),
	"y_rot": 0.0,
	"x_rot": 18.462,
	"traget_rotation": 0
}

var card_transform_data_player := {
	"position": Vector2(960, 879),
	"scale": Vector2(0.335, 0.277),
	"y_rot": 0.0,
	"x_rot": 18.462,
	"traget_rotation": 0
}

var card_transform_data_opponent := {
	"position": Vector2(960, 641),
	"scale": Vector2(0.22, 0.137),
	"y_rot": 0.0,
	"x_rot": 18.462,
	"traget_rotation": 0
}

func _ready() -> void:
	texture = card_back_texture

func send_card_to(card_transform_data: Dictionary):
	var actual_duration = randf_range(0.8, 1.2)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", card_transform_data["position"], actual_duration)
	tween.tween_property(self, "rotation", card_transform_data["traget_rotation"], actual_duration)
	tween.tween_property(self, "scale", card_transform_data["scale"], actual_duration)
	material.set_shader_parameter("x_rot", card_transform_data["x_rot"])
	material.set_shader_parameter("y_rot", card_transform_data["y_rot"])
	
