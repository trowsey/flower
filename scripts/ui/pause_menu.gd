# Shared pause menu — covers all players. Activated with Esc or START.
# Pauses the SceneTree; menu nodes use process_mode = ALWAYS to keep running.
extends CanvasLayer

@onready var _panel: Control = $Panel
@onready var _resume_btn: Button = $Panel/VBox/Resume
@onready var _quit_btn: Button = $Panel/VBox/QuitToMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false
	if _resume_btn:
		_resume_btn.pressed.connect(_resume)
	if _quit_btn:
		_quit_btn.pressed.connect(_quit_to_menu)


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
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
