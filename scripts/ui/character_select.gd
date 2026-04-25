# Character select screen — built programmatically.
# - 1P/2P mode toggle
# - Each player picks a class with controller or kbd
# - Press "attack" to start the game with the selected party
extends Control

const CharacterClassScript = preload("res://scripts/items/character_class.gd")
const MAIN_SCENE := "res://scenes/main.tscn"

@onready var _root: VBoxContainer = $Root
@onready var _title: Label = $Root/Title
@onready var _mode_label: Label = $Root/ModeLabel
@onready var _slots_box: HBoxContainer = $Root/Slots
@onready var _hint_label: Label = $Root/Hint

var _two_player: bool = false
var _selections: Array[int] = [CharacterClassScript.Id.SARAH, CharacterClassScript.Id.MADDIE]
var _ready_state: Array[bool] = [false, false]
var _classes: Array = []


func _ready() -> void:
	_classes = CharacterClassScript.all()
	# Honor requested_player_count from the upstream player_count screen
	if PartyConfig.has_meta("requested_player_count"):
		_two_player = int(PartyConfig.get_meta("requested_player_count")) >= 2
	_refresh()


func _refresh() -> void:
	if _title:
		_title.text = "CHOOSE YOUR HERO"
	if _mode_label:
		_mode_label.text = "%s" % ("2 PLAYERS" if _two_player else "1 PLAYER")
	if _hint_label:
		_hint_label.text = "P1: A/D or LStick to change class, ENTER/X to ready up\n" + \
			("P2: ←/→ on 2nd controller, X to ready up\n" if _two_player else "") + \
			"All players ready → game starts  |  ESC: back"
	_redraw_slots()


func _redraw_slots() -> void:
	if _slots_box == null:
		return
	for c in _slots_box.get_children():
		c.queue_free()
	var n_slots: int = 2 if _two_player else 1
	for i in n_slots:
		var slot := _build_slot(i)
		_slots_box.add_child(slot)


func _build_slot(slot_index: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 360)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var header := Label.new()
	header.text = "PLAYER %d" % (slot_index + 1)
	header.add_theme_font_size_override("font_size", 24)
	v.add_child(header)

	var cls: Resource = _classes[_selections[slot_index]]
	var color_rect := ColorRect.new()
	color_rect.color = cls.primary_color
	color_rect.custom_minimum_size = Vector2(120, 120)
	v.add_child(color_rect)

	var name_label := Label.new()
	name_label.text = cls.display_name
	name_label.add_theme_font_size_override("font_size", 22)
	v.add_child(name_label)

	var arch_label := Label.new()
	arch_label.text = cls.archetype
	v.add_child(arch_label)

	var desc_label := Label.new()
	desc_label.text = cls.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(240, 60)
	v.add_child(desc_label)

	var stats_label := Label.new()
	stats_label.text = "HP %d  Soul %d\nATK %.0f  Spd %.1f\nAtkSpd %.1fx" % [
		int(cls.base_health), int(cls.base_soul),
		cls.base_attack_damage, cls.base_move_speed,
		cls.base_attack_speed
	]
	v.add_child(stats_label)

	var ready_label := Label.new()
	ready_label.text = "READY ✔" if _ready_state[slot_index] else "Choosing..."
	ready_label.modulate = Color(0.4, 1.0, 0.4) if _ready_state[slot_index] else Color.WHITE
	v.add_child(ready_label)

	return panel


func _unhandled_input(event: InputEvent) -> void:
	# Cancel back to player count screen (ESC or B)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/ui/player_count.tscn")
		return
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		get_tree().change_scene_to_file("res://scenes/ui/player_count.tscn")
		return

	# Map device → slot
	var slot_index: int = _slot_for_event(event)
	if slot_index < 0:
		return

	# Class change: left/right
	if _is_left_pressed(event, slot_index):
		_selections[slot_index] = (_selections[slot_index] - 1 + _classes.size()) % _classes.size()
		_ready_state[slot_index] = false
		_refresh()
	elif _is_right_pressed(event, slot_index):
		_selections[slot_index] = (_selections[slot_index] + 1) % _classes.size()
		_ready_state[slot_index] = false
		_refresh()
	elif _is_confirm_pressed(event, slot_index):
		_ready_state[slot_index] = not _ready_state[slot_index]
		_refresh()
		_check_all_ready()


func _slot_for_event(event: InputEvent) -> int:
	# P1 = keyboard or device 0, P2 = device 1+
	if event is InputEventKey:
		return 0
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if not _two_player:
			return 0
		return 0 if event.device == 0 else 1
	return -1


func _is_left_pressed(event: InputEvent, _slot: int) -> bool:
	if event is InputEventKey and event.pressed:
		return event.keycode == KEY_A or event.keycode == KEY_LEFT
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_DPAD_LEFT
	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_X and event.axis_value < -0.5:
		return true
	return false


func _is_right_pressed(event: InputEvent, _slot: int) -> bool:
	if event is InputEventKey and event.pressed:
		return event.keycode == KEY_D or event.keycode == KEY_RIGHT
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_DPAD_RIGHT
	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_X and event.axis_value > 0.5:
		return true
	return false


func _is_confirm_pressed(event: InputEvent, _slot: int) -> bool:
	if event is InputEventKey and event.pressed:
		return event.keycode == KEY_ENTER or event.keycode == KEY_SPACE
	if event is InputEventJoypadButton and event.pressed:
		# X on Xbox = button 2 (already mapped to "attack"), A = 0 = "interact"
		return event.button_index == JOY_BUTTON_A or event.button_index == JOY_BUTTON_X
	return false


func _check_all_ready() -> void:
	var n: int = 2 if _two_player else 1
	for i in n:
		if not _ready_state[i]:
			return
	_start_game()


func _start_game() -> void:
	if _two_player:
		PartyConfig.set_two_player(_selections[0], _selections[1], -1, 1)
	else:
		PartyConfig.set_solo(_selections[0])
	get_tree().change_scene_to_file(MAIN_SCENE)
