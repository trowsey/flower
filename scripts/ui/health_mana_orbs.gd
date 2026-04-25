# Health and mana orbs UI: two TextureRect/ShaderRect orbs that fill based on health/soul.
extends Control
class_name HealthManaOrbs

@export var player_path: NodePath

@onready var health_fill: ColorRect = $HealthOrb/Fill
@onready var soul_fill: ColorRect = $SoulOrb/Fill
@onready var health_label: Label = $HealthOrb/Label
@onready var soul_label: Label = $SoulOrb/Label

var player: Node3D = null


func _ready() -> void:
	if player_path != NodePath(""):
		player = get_node_or_null(player_path)
	else:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
	if player:
		player.health_changed.connect(_on_health_changed)
		player.soul_changed.connect(_on_soul_changed)
		player.max_health_changed.connect(_on_max_health_changed)
		player.max_soul_changed.connect(_on_max_soul_changed)
		_on_health_changed(player.health)
		_on_soul_changed(player.soul)


func _on_health_changed(v: float) -> void:
	if not player or health_fill == null:
		return
	var pct: float = clamp(v / max(1.0, player.stats.max_health()), 0.0, 1.0)
	health_fill.scale.y = pct
	health_fill.position.y = (1.0 - pct) * health_fill.size.y
	if health_label:
		health_label.text = "%d/%d" % [int(v), int(player.stats.max_health())]


func _on_soul_changed(v: float) -> void:
	if not player or soul_fill == null:
		return
	var pct: float = clamp(v / max(1.0, player.stats.max_soul()), 0.0, 1.0)
	soul_fill.scale.y = pct
	soul_fill.position.y = (1.0 - pct) * soul_fill.size.y
	if soul_label:
		soul_label.text = "%d/%d" % [int(v), int(player.stats.max_soul())]


func _on_max_health_changed(_m: float) -> void:
	_on_health_changed(player.health)


func _on_max_soul_changed(_m: float) -> void:
	_on_soul_changed(player.soul)
