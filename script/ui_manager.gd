extends CanvasLayer

enum UIState {NONE, MAIN_MENU, PAUSE_MENU, SETTINGS, DEAL, TELL, QUESTIONMARK, CHIPS}

@onready var main_menu: Control = $MainMenuUI
@onready var pause_menu: Control = $PauseMenuUI
@onready var settings: Control = $SettingMenuUI
@onready var deal_ui: Control = $DealUI
@onready var tell_ui: Control = $TruthLieUI
@onready var question_ui: Control = $QuestionMarkUI
var current_state: UIState

# Chips
@onready var chips_ui: Control = %CoinsUI
@onready var player_coin: Node2D= %CoinsUI/PlayerChips
@onready var opponent_coin: Node2D = %CoinsUI/OpponentChips
@onready var pot_coin: Node2D = %CoinsUI/PotsChips

# Deal Phase
@onready var check: Label = $DealUI/CHECK
@onready var raise: Label = $DealUI/RAISE
@onready var call: Label = $DealUI/CALL
@onready var fold: Label = $DealUI/FOLD
@onready var allin: Label = $DealUI/ALLIN
@onready var liar: Label = $DealUI/LIAR

func _ready() -> void:
	set_state(UIState.MAIN_MENU)
	
func set_state(state: UIState) -> void:
	current_state = state
	main_menu.visible = (state == UIState.MAIN_MENU)
	pause_menu.visible = (state == UIState.PAUSE_MENU)
	settings.visible = (state == UIState.SETTINGS)
	deal_ui.visible = (state == UIState.DEAL)
	tell_ui.visible = (state == UIState.TELL)

func distribute_starting_chips(player: String, starting_chips) -> void:
	if player == "PLAYER":
		player_coin.set_amount(starting_chips)
	else:
		opponent_coin.set_amount(starting_chips)

func set_visible_custom(state: UIState) -> void:
	match state:
		UIState.CHIPS:
			chips_ui.visible = true
		#UIState.QUESTIONMARK:
			#question_ui.visible = true
		
func update_chip_visuals(player_chips: Variant = null, opponent_chips: Variant = null, pot: Variant = null) -> void:
	if player_chips != null:
		player_coin.set_amount(player_chips)
	if opponent_chips != null:
		opponent_coin.set_amount(opponent_chips)
	if pot != null:
		pot_coin.set_amount(pot)

func update_action_visibility(is_player_turn: bool, to_call: int) -> void:
	if not is_player_turn:
		check.visible = false
		raise.visible = false
		call.visible = false
		fold.visible = false
		allin.visible = false
		liar.visible = false
		return
	var facing := to_call > 0
	check.visible = not facing
	raise.visible = true
	call.visible = facing
	fold.visible = true
	allin.visible = true
	liar.visible = true
