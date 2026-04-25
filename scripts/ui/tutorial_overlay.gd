# Tutorial overlay shown to first-time players.
# Built procedurally; instanced from main.gd.
extends CanvasLayer

const SettingsScript = preload("res://scripts/settings.gd")

var _panel: PanelContainer
var _dismissed: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://settings.cfg")
	if err == OK and cfg.get_value("tutorial", "seen", false):
		queue_free()
		return

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.position = Vector2(-220, -180)
	_panel.custom_minimum_size = Vector2(440, 200)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "CONTROLS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	var lines := [
		"Move:       WASD / Left Stick",
		"Attack:     Left-Click / X",
		"Skills:     1-4 / Face Buttons",
		"Dash:       Shift / RB",
		"Inventory:  I / Select",
		"Pause:      Esc / Start",
	]
	for s in lines:
		var l := Label.new()
		l.text = s
		l.add_theme_font_size_override("font_size", 16)
		vbox.add_child(l)

	var hint := Label.new()
	hint.text = "Press any key to begin"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.7, 0.85, 1.0)
	vbox.add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	if _dismissed:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_dismiss()
	elif event is InputEventMouseButton and event.pressed:
		_dismiss()
	elif event is InputEventJoypadButton and event.pressed:
		_dismiss()


func _dismiss() -> void:
	_dismissed = true
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("tutorial", "seen", true)
	cfg.save("user://settings.cfg")
	if _panel:
		var tw := create_tween()
		tw.tween_property(_panel, "modulate:a", 0.0, 0.4)
		tw.tween_callback(queue_free)
	else:
		queue_free()
