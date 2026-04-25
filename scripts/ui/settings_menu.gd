# Settings menu — full settings page reachable from the main menu.
# Lighter version exists in pause_menu.tscn (audio + fullscreen only).
extends Control

const SettingsScript = preload("res://scripts/settings.gd")
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@onready var _master: HSlider = $Center/Scroll/VBox/Audio/MasterRow/Master
@onready var _master_lbl: Label = $Center/Scroll/VBox/Audio/MasterRow/MasterValue if has_node("Center/Scroll/VBox/Audio/MasterRow/MasterValue") else null
@onready var _music: HSlider = $Center/Scroll/VBox/Audio/MusicRow/Music
@onready var _music_lbl: Label = $Center/Scroll/VBox/Audio/MusicRow/MusicValue if has_node("Center/Scroll/VBox/Audio/MusicRow/MusicValue") else null
@onready var _sfx: HSlider = $Center/Scroll/VBox/Audio/SfxRow/Sfx
@onready var _sfx_lbl: Label = $Center/Scroll/VBox/Audio/SfxRow/SfxValue if has_node("Center/Scroll/VBox/Audio/SfxRow/SfxValue") else null
@onready var _fullscreen: CheckBox = $Center/Scroll/VBox/Display/Fullscreen
@onready var _vsync: CheckBox = $Center/Scroll/VBox/Display/Vsync
@onready var _shake: HSlider = $Center/Scroll/VBox/Display/ShakeRow/Shake
@onready var _shake_lbl: Label = $Center/Scroll/VBox/Display/ShakeRow/ShakeValue if has_node("Center/Scroll/VBox/Display/ShakeRow/ShakeValue") else null
@onready var _dmg_numbers: CheckBox = $Center/Scroll/VBox/Gameplay/DamageNumbers
@onready var _magnet: HSlider = $Center/Scroll/VBox/Gameplay/MagnetRow/Magnet
@onready var _magnet_lbl: Label = $Center/Scroll/VBox/Gameplay/MagnetRow/MagnetValue if has_node("Center/Scroll/VBox/Gameplay/MagnetRow/MagnetValue") else null
@onready var _back: Button = $Center/Scroll/VBox/Buttons/Back
@onready var _reset: Button = $Center/Scroll/VBox/Buttons/Reset


func _ready() -> void:
	_load_values()
	_master.value_changed.connect(func(v): SettingsScript.set_master_volume(v); _refresh_labels())
	_music.value_changed.connect(func(v): SettingsScript.set_music_volume(v); _refresh_labels())
	_sfx.value_changed.connect(func(v): SettingsScript.set_sfx_volume(v); _refresh_labels())
	_fullscreen.toggled.connect(SettingsScript.set_fullscreen)
	_vsync.toggled.connect(SettingsScript.set_vsync)
	_shake.value_changed.connect(func(v): SettingsScript.set_camera_shake(v); _refresh_labels())
	_dmg_numbers.toggled.connect(SettingsScript.set_damage_numbers)
	_magnet.value_changed.connect(func(v): SettingsScript.set_loot_magnet_radius(v); _refresh_labels())
	_back.pressed.connect(_back_to_menu)
	_reset.pressed.connect(_reset_defaults)
	_back.grab_focus()
	_refresh_labels()


func _refresh_labels() -> void:
	if _master_lbl: _master_lbl.text = "%+.0f dB" % _master.value
	if _music_lbl: _music_lbl.text = "%+.0f dB" % _music.value
	if _sfx_lbl: _sfx_lbl.text = "%+.0f dB" % _sfx.value
	if _shake_lbl: _shake_lbl.text = "%.0f%%" % (_shake.value * 100.0)
	if _magnet_lbl: _magnet_lbl.text = "%.1f m" % _magnet.value


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
	_refresh_labels()


func _back_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _reset_defaults() -> void:
	SettingsScript.reset_to_defaults()
	_load_values()
