# Credits screen — static text, any-button to go back.
extends Control

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@onready var _back_btn: Button = $Center/VBox/Back


func _ready() -> void:
	_back_btn.pressed.connect(_back)
	_back_btn.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_back()
	elif event is InputEventJoypadButton and event.pressed:
		_back()


func _back() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
