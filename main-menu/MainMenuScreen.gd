class_name MainMenuScreen
extends CanvasLayer

enum Menus { NONE = 0, MAIN, NEW, LOAD, SETTINGS }

var _current_menu: int = Menus.MAIN

onready var _main_menu_container: MarginContainer = $MainMenuContainer
onready var _new_game_container: BaseMainMenuContainer = $NewGameContainer
onready var _load_game_container: BaseMainMenuContainer = $LoadGameContainer
onready var _settings_container: BaseMainMenuContainer = $SettingsContainer

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	$MainMenuContainer/MainMenu/ContinueButton.connect("pressed", self, "_on_continue_button_pressed")
	$MainMenuContainer/MainMenu/NewButton.connect("pressed", self, "_on_new_button_pressed")
	$MainMenuContainer/MainMenu/LoadButton.connect("pressed", self, "_on_load_button_pressed")
	$MainMenuContainer/MainMenu/PracticeButton.connect("pressed", self, "_on_practice_button_pressed")
	$MainMenuContainer/MainMenu/SettingsButton.connect("pressed", self, "_on_settings_button_pressed")
	$MainMenuContainer/MainMenu/QuitButton.connect("pressed", self, "_on_quit_button_pressed")
	
	_new_game_container.connect("back_button_pressed", self, "_on_new_game_container_back_button_pressed")
	_load_game_container.connect("back_button_pressed", self, "_on_load_game_container_back_button_pressed")
	_settings_container.connect("back_button_pressed", self, "_on_settings_container_back_button_pressed")

###############################################################################
# Connections                                                                 #
###############################################################################

# TODO testing, goes straight to game
func _on_continue_button_pressed() -> void:
	get_tree().change_scene("res://screens/battle/BattleScreen.tscn")

func _on_new_button_pressed() -> void:
	switch_menu_to(Menus.NEW)

func _on_load_button_pressed() -> void:
	switch_menu_to(Menus.LOAD)

func _on_practice_button_pressed() -> void:
	GameManager.log_message("Not yet implemented: %s" % "Practice Button")

func _on_settings_button_pressed() -> void:
	switch_menu_to(Menus.SETTINGS)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_new_game_container_back_button_pressed() -> void:
	switch_menu_to(Menus.MAIN)

func _on_load_game_container_back_button_pressed() -> void:
	switch_menu_to(Menus.MAIN)

func _on_settings_container_back_button_pressed() -> void:
	switch_menu_to(Menus.MAIN)

###############################################################################
# Private functions                                                           #
###############################################################################

func switch_menu_to(menu: int) -> void:
	if menu == _current_menu:
		return
	_toggle_menu(_current_menu)
	_toggle_menu(menu)
	_current_menu = menu

func _toggle_menu(menu: int) -> void:
	match menu:
		Menus.NONE:
			pass
		Menus.MAIN:
			_main_menu_container.visible = not _main_menu_container.visible
		Menus.NEW:
			_new_game_container.visible = not _new_game_container.visible
		Menus.LOAD:
			_load_game_container.visible = not _load_game_container.visible
		Menus.SETTINGS:
			_settings_container.visible = not _settings_container.visible

###############################################################################
# Public functions                                                            #
###############################################################################


