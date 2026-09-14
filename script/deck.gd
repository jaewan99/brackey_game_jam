extends Node

@export var card_scene: PackedScene
@export var cards_container: Node

var deck: Array[int] = []

const SUITS := ["spades","hearts"]
const RANK_NAMES := {
	2: "2", 3: "3", 4: "4", 5: "5", 6: "6",
	7: "7", 8: "8", 9: "9", 10: "10",
	11: "jack", 12: "queen", 13: "king", 14: "ace"
}

func _ready() -> void:
	_build_deck()

func _build_deck() -> void:
	deck.clear()
	for i in range(26):
		deck.append(i)
	deck.shuffle()

func draw_card() -> int:
	if deck.is_empty():
		_build_deck()
	return deck.pop_back()

func get_rank(card_id:int) -> int:
	return (card_id % 13) + 2

func get_suit(card_id:int) -> String:
	return SUITS[card_id / 13]
	
func get_card_texture_path(card_id:int) -> String:
	var rank_name: String = RANK_NAMES[get_rank(card_id)]
	var suit: String = get_suit(card_id)
	return "res://card/cards/%s_of_%s.png" % [rank_name, suit]
	
func spawn_card_at_marker(spawn_point: Vector2, _card_id:int, is_player: bool) -> Sprite2D:
	var card_instance = card_scene.instantiate()
	if is_player: card_instance.is_player = true
	else: card_instance.is_player = false
	cards_container.add_child(card_instance)
	card_instance.global_position = spawn_point
	return card_instance
	
func get_random_card_excluding(exclude_card_id: int) -> int:
	var candidates: Array[int] = []
	for i in range(26):
		if i != exclude_card_id:
			candidates.append(i)
	return candidates[randi() % candidates.size()]
