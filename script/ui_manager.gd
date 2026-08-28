extends CanvasLayer

enum UIState {NONE, MAIN_MENU, PAUSE_MENU, SETTINGS, DEAL}

@onready var main_menu: Control = $MainMenuUI
@onready var pause_menu: Control = $PauseMenuUI
@onready var settings: Control = $SettingMenuUI
@onready var deal_ui: Control = $DealUI

var current_state: UIState

func _ready() -> void:
	set_state(UIState.MAIN_MENU)
	
func set_state(state: UIState) -> void:
	current_state = state
	main_menu.visible = (state == UIState.MAIN_MENU)
	pause_menu.visible = (state == UIState.PAUSE_MENU)
	settings.visible = (state == UIState.SETTINGS)
	deal_ui.visible = (state == UIState.DEAL)
