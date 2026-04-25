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
		if gold_label:
			gold_label.text = "Gold: %d" % player.gold
		if level_label and player.stats:
			level_label.text = "Lv %d" % player.stats.level

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
					l.text = "[%d] %s" % [i + 1, player.skills[i].skill_name.left(8)]
					l.modulate = Color.WHITE
			else:
				l.text = "[%d] —" % (i + 1)
				l.modulate = Color(0.4, 0.4, 0.4)


@onready var _left_anchor: Control = $LeftAnchor
@onready var _right_anchor: Control = $RightAnchor
var _panels: Array = []


func _ready() -> void:
	# Wait one frame so players are in the tree
	await get_tree().process_frame
	_build_panels()


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
	if p.has_signal("level_up"):
		p.level_up.connect(func(_v): panel._refresh())


func _process(_delta: float) -> void:
	# Skill cooldowns tick continuously
	for panel in _panels:
		panel.update_skills()
