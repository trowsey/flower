# Main menu — game entry point.
# Vertical button stack with controller / keyboard navigation.
extends Control

const SettingsScript = preload("res://scripts/settings.gd")

const PLAYER_COUNT_SCENE := "res://scenes/ui/player_count.tscn"
const SETTINGS_SCENE := "res://scenes/ui/settings_menu.tscn"
const CREDITS_SCENE := "res://scenes/ui/credits.tscn"

@onready var _new_btn: Button = $Center/VBox/NewGame
@onready var _settings_btn: Button = $Center/VBox/Settings
@onready var _credits_btn: Button = $Center/VBox/Credits
@onready var _quit_btn: Button = $Center/VBox/Quit
@onready var _version_label: Label = get_node_or_null("VersionLabel")


func _ready() -> void:
	SettingsScript.load_and_apply()
	_new_btn.pressed.connect(_new_game)
	_settings_btn.pressed.connect(_open_settings)
	_credits_btn.pressed.connect(_open_credits)
	_quit_btn.pressed.connect(_quit)
	_new_btn.grab_focus()
	if _version_label:
		_version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version", "0.1")


func _new_game() -> void:
	get_tree().change_scene_to_file(PLAYER_COUNT_SCENE)


func _open_settings() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE)


func _open_credits() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE)


func _quit() -> void:
	get_tree().quit()
