extends Node2D

@export var chip_texture: Texture2D
@export var chips_per_stack: int = 10   # cap per visual pile
@export var stack_offset: float = 14.0   # vertical gap between chips in one pile
@export var pile_spacing: float = 90.0  # horizontal gap between piles
@export var stack_z_index: int

@onready var count_label: Label = $ChipsCount

var _chips_root: Node2D
var _current_amount: int = 0   # how many chips the stack is currently showing
var _hovering := false

func _ready() -> void:
	_chips_root = Node2D.new()
	add_child(_chips_root)
	count_label.visible = false

func _process(_delta: float) -> void:
	# get_local_mouse_position() already undoes this node's scale/position,
	# so it matches the stack's local coordinates.
	var inside := _current_amount > 0 and _stack_rect().has_point(get_local_mouse_position())
	if inside and not _hovering:
		_hovering = true
		count_label.visible = true
		_position_label()
	elif not inside and _hovering:
		_hovering = false
		count_label.visible = false
	
func set_amount(amount: int) -> void:
	_current_amount = amount
	count_label.text = str(amount)
	
	#clear the previous stack
	for child in _chips_root.get_children():
		child.queue_free()
	if amount <= 0:
		return
	var pile_count: int = int(ceil(float(amount) / chips_per_stack))
	var start_x: float = -(pile_count - 1) * pile_spacing * 0.5
	for i in amount:
		var pile: int = i / chips_per_stack       # which pile this chip lands in
		var height: int = i % chips_per_stack     # how high up that pile

		var sprite := Sprite2D.new()
		sprite.texture = chip_texture
		sprite.z_index = stack_z_index
		sprite.position = Vector2(
			start_x + pile * pile_spacing,
			-height * stack_offset,               # stack upward
		)
		_chips_root.add_child(sprite)
	if count_label.visible:
		_position_label()
		
# Local position of chip #i within a stack of `pile_count` piles.
func _chip_pos(i: int, pile_count: int) -> Vector2:
	var start_x := -(pile_count - 1) * pile_spacing * 0.5
	var pile := i / chips_per_stack
	var height := i % chips_per_stack
	return Vector2(start_x + pile * pile_spacing, -height * stack_offset)


func fly_to(target_global: Vector2, count: int, duration: float = 0.45) -> void:
	count = mini(count, _current_amount)
	if count <= 0:
		return
	
	var layer := get_parent()
	var pile_count := int(ceil(float(_current_amount) / chips_per_stack))
	var flyers: Array[Sprite2D] = []
	for n in count:
		var idx := _current_amount - 1 - n            # take from the top
		var s := Sprite2D.new()
		s.texture = chip_texture
	
		layer.add_child(s)
		s.z_index = stack_z_index
		s.global_scale = global_scale
		# flyers live under self (not _chips_root) so set_amount() won't free them
		s.global_position = _chips_root.to_global(_chip_pos(idx, pile_count))
		
		flyers.append(s)
	
	# Immediately drop those chips from the source stack so they appear to leave.
	set_amount(_current_amount - count)
	
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	for n in flyers.size():
		var dest := target_global + Vector2(0, -(n % chips_per_stack) * stack_offset)
		tween.tween_property(flyers[n], "global_position", dest, duration) \
			.set_delay(n * 0.03)   # small stagger so they cascade

	await tween.finished
	for s in flyers:
		s.queue_free()
		
# Grow this stack by `delta` (used when chips land here).
func add_amount(delta: int) -> void:
	set_amount(_current_amount + delta)

# Bounding box of the whole stack in this node's local space.
func _stack_rect() -> Rect2:
	if _current_amount <= 0:
		return Rect2()
	var pile_count := int(ceil(float(_current_amount) / chips_per_stack))
	var tallest := mini(_current_amount, chips_per_stack)   # pile 0 is always tallest
	var cw := chip_texture.get_width()
	var ch := chip_texture.get_height()
	var start_x := -(pile_count - 1) * pile_spacing * 0.5
	var left   := start_x - cw * 0.5
	var right  := start_x + (pile_count - 1) * pile_spacing + cw * 0.5
	var top    := -(tallest - 1) * stack_offset - ch * 0.5  # grows upward with chip count
	var bottom := ch * 0.5
	return Rect2(left, top, right - left, bottom - top)

func _position_label() -> void:
	var center := _stack_rect().get_center()
	var sz := count_label.get_combined_minimum_size()   # the text's own size
	count_label.size = sz
	count_label.position = center - sz * 0.5            # top-left so its center lands on the stack center


	
