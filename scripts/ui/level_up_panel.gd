# Level-up toast + stat allocation panel.
# Listens to all players' level_up signals; toggle stat panel with `character` action
# (default: C). Time does not pause.
extends CanvasLayer

const STAT_KEYS: Array = ["strength", "vitality", "spirit", "agility"]
const STAT_LABELS: Dictionary = {
	"strength": "Strength  (+2 ATK)",
	"vitality": "Vitality  (+10 HP)",
	"spirit":   "Spirit    (+10 Soul)",
	"agility":  "Agility   (+0.1 AS / +0.3 MS)",
}

var _toast: Label
var _panel: PanelContainer
var _stat_labels: Dictionary = {}  # key -> Label
var _plus_buttons: Dictionary = {}  # key -> Button
var _points_label: Label
var _level_label: Label

var _viewing_player_idx: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 60
	_build_toast()
	_build_panel()
	await get_tree().process_frame
	_attach_players()


func _attach_players() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_signal("level_up"):
			p.level_up.connect(_on_level_up.bind(p))


func _on_level_up(_lv: int, p: Node) -> void:
	_show_toast("LEVEL UP! → %d" % p.stats.level)


func _build_toast() -> void:
	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.position = Vector2(-120, 60)
	_toast.custom_minimum_size = Vector2(240, 32)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 22)
	_toast.modulate = Color(1, 0.85, 0.2, 0)
	add_child(_toast)


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-180, -160)
	_panel.custom_minimum_size = Vector2(360, 320)
	_panel.visible = false
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "STAT ALLOCATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	_level_label = Label.new()
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_level_label)

	_points_label = Label.new()
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_points_label.modulate = Color(1, 0.85, 0.2)
	vbox.add_child(_points_label)

	for key in STAT_KEYS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)
		var l := Label.new()
		l.custom_minimum_size = Vector2(220, 0)
		_stat_labels[key] = l
		row.add_child(l)
		var plus := Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(40, 28)
		var k: String = key
		plus.pressed.connect(func(): _spend(k))
		_plus_buttons[key] = plus
		row.add_child(plus)

	var sep := HSeparator.new()
	vbox.add_child(sep)
	var close := Button.new()
	close.text = "Done"
	close.pressed.connect(_close_panel)
	vbox.add_child(close)


func _unhandled_input(event: InputEvent) -> void:
	# Open via 'character' action if mapped, else 'C'
	var open_pressed := false
	if InputMap.has_action("character") and event.is_action_pressed("character"):
		open_pressed = true
	elif event is InputEventKey and event.pressed and event.keycode == KEY_C and not event.echo:
		open_pressed = true
	if open_pressed:
		_toggle_panel()
		get_viewport().set_input_as_handled()
		return
	if _panel.visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_panel()
		get_viewport().set_input_as_handled()


func _toggle_panel() -> void:
	if _panel.visible:
		_close_panel()
	else:
		_cycle_to_player_with_points()
		_panel.visible = true
		_refresh()


func _close_panel() -> void:
	_panel.visible = false


func _cycle_to_player_with_points() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	for offset in players.size():
		var idx: int = (_viewing_player_idx + offset) % players.size()
		var p = players[idx]
		if p.stats and p.stats.stat_points > 0:
			_viewing_player_idx = idx
			return
	# Nobody has points; just show first
	_viewing_player_idx = 0


func _current_player() -> Node:
	var players := get_tree().get_nodes_in_group("player")
	if _viewing_player_idx >= players.size():
		_viewing_player_idx = 0
	return players[_viewing_player_idx] if players.size() > 0 else null


func _spend(key: String) -> void:
	var p := _current_player()
	if p == null or p.stats == null:
		return
	if p.stats.spend_stat_point(key):
		_refresh()


func _refresh() -> void:
	var p := _current_player()
	if p == null or p.stats == null:
		return
	_level_label.text = "P%d  Level %d" % [p.player_index + 1, p.stats.level]
	_points_label.text = "Points to spend: %d" % p.stats.stat_points
	for key in STAT_KEYS:
		var v: int = p.stats.get(key)
		_stat_labels[key].text = "%-30s %d" % [STAT_LABELS[key], v]
		_plus_buttons[key].disabled = p.stats.stat_points <= 0
