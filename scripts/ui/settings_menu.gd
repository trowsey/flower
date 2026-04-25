# Settings menu — full settings page reachable from the main menu.
# Lighter version exists in pause_menu.tscn (audio + fullscreen only).
extends Control

const SettingsScript = preload("res://scripts/settings.gd")
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@onready var _master: HSlider = $Center/Scroll/VBox/Audio/MasterRow/Master
@onready var _music: HSlider = $Center/Scroll/VBox/Audio/MusicRow/Music
@onready var _sfx: HSlider = $Center/Scroll/VBox/Audio/SfxRow/Sfx
@onready var _fullscreen: CheckBox = $Center/Scroll/VBox/Display/Fullscreen
@onready var _vsync: CheckBox = $Center/Scroll/VBox/Display/Vsync
@onready var _shake: HSlider = $Center/Scroll/VBox/Display/ShakeRow/Shake
@onready var _dmg_numbers: CheckBox = $Center/Scroll/VBox/Gameplay/DamageNumbers
@onready var _magnet: HSlider = $Center/Scroll/VBox/Gameplay/MagnetRow/Magnet
@onready var _back: Button = $Center/Scroll/VBox/Buttons/Back
@onready var _reset: Button = $Center/Scroll/VBox/Buttons/Reset


func _ready() -> void:
	_load_values()
	_master.value_changed.connect(SettingsScript.set_master_volume)
	_music.value_changed.connect(SettingsScript.set_music_volume)
	_sfx.value_changed.connect(SettingsScript.set_sfx_volume)
	_fullscreen.toggled.connect(SettingsScript.set_fullscreen)
	_vsync.toggled.connect(SettingsScript.set_vsync)
	_shake.value_changed.connect(SettingsScript.set_camera_shake)
	_dmg_numbers.toggled.connect(SettingsScript.set_damage_numbers)
	_magnet.value_changed.connect(SettingsScript.set_loot_magnet_radius)
	_back.pressed.connect(_back_to_menu)
	_reset.pressed.connect(_reset_defaults)
	_back.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_back_to_menu()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		_back_to_menu()


func _load_values() -> void:
	_master.value = SettingsScript.get_master_volume()
	_music.value = SettingsScript.get_music_volume()
	_sfx.value = SettingsScript.get_sfx_volume()
	_fullscreen.button_pressed = SettingsScript.get_fullscreen()
	_vsync.button_pressed = SettingsScript.get_vsync()
	_shake.value = SettingsScript.get_camera_shake()
	_dmg_numbers.button_pressed = SettingsScript.get_damage_numbers()
	_magnet.value = SettingsScript.get_loot_magnet_radius()


func _back_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _reset_defaults() -> void:
	SettingsScript.reset_to_defaults()
	_load_values()
