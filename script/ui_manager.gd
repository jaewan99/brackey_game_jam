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

func send_chips(from:Node2D, to:Node2D, amount:int) -> void:
	await from.fly_to(to.global_position, amount)
	to.add_amount(amount)

func set_visible_custom(state: UIState) -> void:
	match state:
		UIState.CHIPS:
			chips_ui.visible = true
		

# TODO fix this since there are edge cases
func update_action_visibility(is_player_turn: bool, to_call: int, player_chips: int, opponent_chips: int, bet_unit: int = 3) -> void:
	if not is_player_turn:
		_hide_all_actions()
		return
	var facing := to_call > 0
	var can_act := player_chips > 0
	var opp_live := opponent_chips > 0
	var can_call := facing and player_chips >= to_call
	var full_raise := player_chips >= to_call + bet_unit
	var raise_ok := full_raise and opponent_chips > 0
	
	check.visible = can_act and not facing
	call.visible = can_act and can_call
	raise.visible = can_act and raise_ok and opp_live
	allin.visible = can_act and opp_live
	fold.visible = true # can always fold
	liar.visible = true

func _hide_all_actions():
	for lbl in [check, raise, call, fold, allin, liar]:
		lbl.visible = false
