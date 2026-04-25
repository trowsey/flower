# Audio manager — switches ambient/combat tracks based on enemy proximity
extends Node
class_name AmbientAudio

@export var ambient_player: NodePath
@export var combat_player: NodePath
@export var combat_radius: float = 10.0

var _ambient: AudioStreamPlayer = null
var _combat: AudioStreamPlayer = null
var _in_combat: bool = false


func _ready() -> void:
	if ambient_player != NodePath(""):
		_ambient = get_node_or_null(ambient_player)
	if combat_player != NodePath(""):
		_combat = get_node_or_null(combat_player)


func _process(_delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var p: Node3D = players[0]
	var enemies := get_tree().get_nodes_in_group("enemies")
	var near := false
	for e in enemies:
		if is_instance_valid(e) and e.global_position.distance_to(p.global_position) < combat_radius:
			near = true
			break
	if near != _in_combat:
		_in_combat = near
		_swap()


func _swap() -> void:
	if _ambient:
		_ambient.volume_db = -10.0 if _in_combat else 0.0
	if _combat:
		_combat.volume_db = 0.0 if _in_combat else -80.0
