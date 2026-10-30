extends CanvasLayer

enum UIState {NONE, MAIN_MENU, PAUSE_MENU, SETTINGS, DEAL, TELL, QUESTIONMARK, CHIPS}


@onready var main_menu: Control = $MainMenuUI
@onready var pause_menu: Control = $PauseMenuUI
@onready var settings: Control = $SettingMenuUI
@onready var deal_ui: Control = $DealUI
@onready var tell_ui: Control = $TruthLieUI
var current_state: UIState

# Chips
@onready var chips_ui: Control = %CoinsUI
@onready var player_coin: Node2D= %PlayerChips
@onready var opponent_coin: Node2D = %OpponentChips
@onready var pot_coin: Node2D = %PotsChips

# Deal Phase
@onready var check: Button = $DealUI/CHECK
@onready var raise: Button = $DealUI/RAISE
@onready var callBtn: Button = $DealUI/CALL
@onready var fold: Button = $DealUI/FOLD
@onready var allin: Button = $DealUI/ALLIN
@onready var liar: Button = $DealUI/LIAR

func _ready() -> void:
	set_state(UIState.MAIN_MENU)
	
func set_state(state: UIState) -> void:
	current_state = state
	main_menu.visible = (state == UIState.MAIN_MENU)
	pause_menu.visible = (state == UIState.PAUSE_MENU)
	settings.visible = (state == UIState.SETTINGS)
	deal_ui.visible = (state == UIState.DEAL)
	tell_ui.visible = (state == UIState.TELL)

func send_chips(from:Node2D, to:Node2D, amount:int) -> void:
	await from.fly_to(to.global_position, amount)
	to.add_amount(amount)

func set_visible_custom(state: UIState) -> void:
	match state:
		UIState.CHIPS:
			chips_ui.visible = true
		

func update_action_visibility(is_player_turn: bool, legal: Array) -> void:
	if not is_player_turn:
		_hide_all_actions()
		return
	check.visible = Action.Type.CHECK in legal
	callBtn.visible  = Action.Type.CALL in legal
	raise.visible = Action.Type.RAISE in legal
	allin.visible = Action.Type.ALLIN in legal
	fold.visible  = Action.Type.FOLD in legal
	liar.visible  = Action.Type.LIAR in legal

func _hide_all_actions():
	for lbl in [check, raise, call, fold, allin, liar]:
		lbl.visible = false
