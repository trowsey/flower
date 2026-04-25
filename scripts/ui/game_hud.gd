# Game HUD — top-level CanvasLayer that builds a per-player display panel
# (health, soul, gold, level, xp, skill names + cooldowns) for every node in
# the "player" group. P1 sits bottom-left, P2 bottom-right (when present).
extends CanvasLayer

const PANEL_MARGIN := 16.0


class PlayerPanel:
	extends VBoxContainer
	var player: Node = null
	var hp_bar: ProgressBar
	var soul_bar: ProgressBar
	var xp_bar: ProgressBar
	var gold_label: Label
	var level_label: Label
	var name_label: Label
	var skill_labels: Array = []

	func attach(p: Node) -> void:
		player = p
		add_theme_constant_override("separation", 4)
		custom_minimum_size = Vector2(280, 0)

		name_label = Label.new()
		add_child(name_label)

		hp_bar = ProgressBar.new()
		hp_bar.show_percentage = false
		hp_bar.custom_minimum_size = Vector2(260, 18)
		hp_bar.modulate = Color(1, 0.4, 0.35)
		add_child(hp_bar)

		soul_bar = ProgressBar.new()
		soul_bar.show_percentage = false
		soul_bar.custom_minimum_size = Vector2(260, 14)
		soul_bar.modulate = Color(0.4, 0.7, 1)
		add_child(soul_bar)

		xp_bar = ProgressBar.new()
		xp_bar.show_percentage = false
		xp_bar.custom_minimum_size = Vector2(260, 6)
		xp_bar.modulate = Color(1, 0.85, 0.2)
		add_child(xp_bar)

		var info := HBoxContainer.new()
		level_label = Label.new()
		gold_label = Label.new()
		info.add_child(level_label)
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(20, 0)
		info.add_child(spacer)
		info.add_child(gold_label)
		add_child(info)

		var skill_row := HBoxContainer.new()
		skill_row.add_theme_constant_override("separation", 4)
		for i in 4:
			var l := Label.new()
			l.custom_minimum_size = Vector2(60, 18)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			skill_labels.append(l)
			skill_row.add_child(l)
		add_child(skill_row)
		_refresh()

	func _refresh() -> void:
		if player == null:
			return
		if name_label:
			var idx: int = player.get("player_index") if player.get("player_index") != null else 0
			name_label.text = "P%d" % (idx + 1)
		if hp_bar and player.stats:
			hp_bar.max_value = player.stats.max_health()
			hp_bar.value = player.health
		if soul_bar and player.stats:
			soul_bar.max_value = player.stats.max_soul()
			soul_bar.value = player.soul
		if xp_bar and player.stats:
			var to_next: float = player.stats.xp_to_next_level()
			xp_bar.max_value = max(1.0, to_next)
			xp_bar.value = clamp(player.stats.xp, 0.0, to_next)
		if gold_label:
			gold_label.text = "Gold: %d" % player.gold
		if level_label and player.stats:
			var marker: String = "  +" if player.stats.stat_points > 0 else ""
			level_label.text = "Lv %d%s" % [player.stats.level, marker]

	func update_skills() -> void:
		if player == null:
			return
		for i in skill_labels.size():
			var l: Label = skill_labels[i]
			if i < player.skills.size() and player.skills[i] != null:
				var cd: float = player.skill_cooldowns[i] if i < player.skill_cooldowns.size() else 0.0
				if cd > 0.0:
					l.text = "[%d] %.1fs" % [i + 1, cd]
					l.modulate = Color(0.6, 0.6, 0.6)
				else:
					l.text = "[%d] %s" % [i + 1, player.skills[i].skill_name.left(10)]
					l.modulate = Color.WHITE
			else:
				l.text = "[%d] —" % (i + 1)
				l.modulate = Color(0.4, 0.4, 0.4)


@onready var _left_anchor: Control = $LeftAnchor
@onready var _right_anchor: Control = $RightAnchor
var _panels: Array = []
var _wave_label: Label
var _enemy_label: Label


func _ready() -> void:
	_build_wave_banner()
	# Wait one frame so players are in the tree
	await get_tree().process_frame
	_build_panels()
	_wire_main_signals()


func _build_wave_banner() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.position = Vector2(-100, 8)
	box.custom_minimum_size = Vector2(200, 0)
	box.add_theme_constant_override("separation", 0)
	add_child(box)
	_wave_label = Label.new()
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_label.add_theme_font_size_override("font_size", 22)
	_wave_label.text = "WAVE 1"
	box.add_child(_wave_label)
	_enemy_label = Label.new()
	_enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_label.add_theme_font_size_override("font_size", 14)
	_enemy_label.modulate = Color(0.85, 0.85, 0.85)
	box.add_child(_enemy_label)


func _wire_main_signals() -> void:
	var main := get_tree().current_scene
	if main and main.has_signal("wave_started"):
		main.wave_started.connect(_on_wave_started)
	if main and main.has_signal("biome_changed"):
		main.biome_changed.connect(_on_biome_changed)


func _on_wave_started(wave: int) -> void:
	if _wave_label:
		var biome_name := ""
		var main := get_tree().current_scene
		if main and main.has_method("current_biome"):
			var b = main.current_biome()
			if b:
				biome_name = " — " + b.display_name
		_wave_label.text = "WAVE %d%s" % [wave, biome_name]
		var tw := create_tween()
		_wave_label.modulate = Color(1, 0.85, 0.2)
		_wave_label.scale = Vector2(1.4, 1.4)
		_wave_label.pivot_offset = _wave_label.size * 0.5
		tw.parallel().tween_property(_wave_label, "scale", Vector2.ONE, 0.4)
		tw.parallel().tween_property(_wave_label, "modulate", Color.WHITE, 0.4)


func _on_biome_changed(_biome) -> void:
	# Refresh wave label with new biome name
	var main := get_tree().current_scene
	if main and "current_wave" in main:
		_on_wave_started(main.current_wave)


func _build_panels() -> void:
	var players := get_tree().get_nodes_in_group("player")
	players.sort_custom(func(a, b): return a.player_index < b.player_index)
	for p in players:
		var panel := PlayerPanel.new()
		var anchor := _left_anchor if p.player_index == 0 else _right_anchor
		anchor.add_child(panel)
		panel.attach(p)
		_panels.append(panel)
		_wire_signals(p, panel)


func _wire_signals(p: Node, panel: PlayerPanel) -> void:
	if p.has_signal("health_changed"):
		p.health_changed.connect(func(_v): panel._refresh())
	if p.has_signal("soul_changed"):
		p.soul_changed.connect(func(_v): panel._refresh())
	if p.has_signal("gold_changed"):
		p.gold_changed.connect(func(_v): panel._refresh())
	if p.has_signal("max_health_changed"):
		p.max_health_changed.connect(func(_v): panel._refresh())
	if p.has_signal("max_soul_changed"):
		p.max_soul_changed.connect(func(_v): panel._refresh())
	if p.has_signal("xp_gained"):
		p.xp_gained.connect(func(_v): panel._refresh())
	if p.has_signal("level_up"):
		p.level_up.connect(func(_v): panel._refresh())


func _process(_delta: float) -> void:
	# Skill cooldowns tick continuously
	for panel in _panels:
		panel.update_skills()
	if _enemy_label:
		var n := get_tree().get_nodes_in_group("enemies").size()
		_enemy_label.text = "Enemies: %d" % n if n > 0 else "Wave clear — next in 8s"
