# Player count selection screen.
# Determines whether the upcoming character_select shows 1 or 2 player slots.
extends Control

const CHARACTER_SELECT_SCENE := "res://scenes/ui/character_select.tscn"
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@onready var _one_btn: Button = $Center/VBox/Cards/OnePlayer
@onready var _two_btn: Button = $Center/VBox/Cards/TwoPlayer
@onready var _hint: Label = $Center/VBox/Hint
@onready var _back_btn: Button = $Center/VBox/Back

# Whether a 2nd controller has been detected (ready_to_2p)
var _second_controller_ready: bool = false


func _ready() -> void:
	_one_btn.pressed.connect(_pick.bind(1))
	_two_btn.pressed.connect(_pick.bind(2))
	_back_btn.pressed.connect(_back)
	_one_btn.grab_focus()
	_refresh()
	# Check on each tick whether more controllers are connected
	Input.joy_connection_changed.connect(_on_joy_changed)


func _process(_delta: float) -> void:
	# Watch for any joy event from a non-zero device
	pass


func _unhandled_input(event: InputEvent) -> void:
	# Esc backs out
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_back()
		return
	# Joypad B / Circle backs out
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		_back()
		return
	# Press any button on joypad >0 to register P2
	if event is InputEventJoypadButton and event.pressed and event.device > 0:
		_second_controller_ready = true
		_refresh()


func _on_joy_changed(_device: int, _connected: bool) -> void:
	# When another controller plugs in/out, update hint text
	_refresh()


func _refresh() -> void:
	var connected_joys: int = Input.get_connected_joypads().size()
	if _hint:
		if connected_joys >= 2 or _second_controller_ready:
			_hint.text = "2nd controller ready ✔"
			_hint.modulate = Color(0.6, 1.0, 0.6)
		else:
			_hint.text = "Plug in or press any button on a 2nd controller for couch co-op"
			_hint.modulate = Color(0.7, 0.7, 0.7)


func _pick(count: int) -> void:
	# Stash the chosen count so character_select knows whether to show P2 slot
	PartyConfig.set_meta("requested_player_count", count)
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)


func _back() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
