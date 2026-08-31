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
@onready var chips_ui: Control = $CoinsUI
@onready var player_coin: Node2D= $CoinsUI/PlayerChips
@onready var opponent_coin: Node2D = $CoinsUI/OpponentChips
func _ready() -> void:
	set_state(UIState.MAIN_MENU)
	
func set_state(state: UIState) -> void:
	current_state = state
	main_menu.visible = (state == UIState.MAIN_MENU)
	pause_menu.visible = (state == UIState.PAUSE_MENU)
	settings.visible = (state == UIState.SETTINGS)
	deal_ui.visible = (state == UIState.DEAL)
	tell_ui.visible = (state == UIState.TELL)
	question_ui.visible = (state == UIState.QUESTIONMARK)

func distribute_starting_chips(player: String, starting_chips) -> void:
	if player == "PLAYER":
		player_coin.set_amount(starting_chips)
	else:
		opponent_coin.set_amount(starting_chips)

func set_visible_custom(state: UIState) -> void:
	match state:
		UIState.CHIPS:
			chips_ui.visible = true
