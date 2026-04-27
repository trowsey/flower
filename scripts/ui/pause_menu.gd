# Shared pause menu — covers all players. Activated with Esc or START.
# Pauses the SceneTree; menu nodes use process_mode = ALWAYS to keep running.
extends CanvasLayer

const Settings = preload("res://scripts/settings.gd")

@onready var _panel: Control = $Panel
@onready var _resume_btn: Button = $Panel/VBox/Resume
@onready var _quit_btn: Button = $Panel/VBox/QuitToMenu
@onready var _volume: HSlider = get_node_or_null("Panel/VBox/VolumeRow/Volume")
@onready var _fullscreen: CheckBox = get_node_or_null("Panel/VBox/Fullscreen")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false
	if _resume_btn:
		_resume_btn.pressed.connect(_resume)
	if _quit_btn:
		_quit_btn.pressed.connect(_quit_to_menu)
	if _volume:
		_volume.value = Settings.get_master_volume()
		_volume.value_changed.connect(func(v): Settings.set_master_volume(v))
	if _fullscreen:
		_fullscreen.button_pressed = Settings.get_fullscreen()
		_fullscreen.toggled.connect(func(on): Settings.set_fullscreen(on))
	_install_controls_help()


func _install_controls_help() -> void:
	var vbox: Node = get_node_or_null("Panel/VBox")
	if vbox == null:
		return
	var help := Label.new()
	help.name = "ControlsHelp"
	help.add_theme_font_size_override("font_size", 12)
	help.modulate = Color(0.75, 0.75, 0.75)
	help.text = "Controls\n  WASD / Stick — move\n  LMB / X — attack\n  Space / A — dash\n  I — inventory   C — character\n  1-4 — skills\n  Esc / Start — pause"
	vbox.add_child(help)


func _unhandled_input(event: InputEvent) -> void:
	if _is_pause_event(event):
		_toggle()
		get_viewport().set_input_as_handled()


func _is_pause_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_ESCAPE
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_START
	return false


func _toggle() -> void:
	var paused: bool = not get_tree().paused
	get_tree().paused = paused
	_panel.visible = paused


func _resume() -> void:
	get_tree().paused = false
	_panel.visible = false


func _quit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
