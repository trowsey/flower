# Audio manager — switches ambient/combat tracks based on enemy proximity
extends Node
class_name AmbientAudio

@export var ambient_player: NodePath
@export var combat_player: NodePath
@export var combat_radius: float = 10.0

var _ambient: AudioStreamPlayer = null
var _combat: AudioStreamPlayer = null
var _in_combat: bool = false
var _check_accum: float = 0.0
const CHECK_INTERVAL := 0.2  # 5 Hz; music transitions don't need 60 Hz polling


func _ready() -> void:
	if ambient_player != NodePath(""):
		_ambient = get_node_or_null(ambient_player)
	if combat_player != NodePath(""):
		_combat = get_node_or_null(combat_player)


func _process(delta: float) -> void:
	_check_accum += delta
	if _check_accum < CHECK_INTERVAL:
		return
	_check_accum = 0.0
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var p: Node3D = players[0]
	var enemies := get_tree().get_nodes_in_group("enemies")
	var near := false
	var combat_radius_sq := combat_radius * combat_radius
	for e in enemies:
		if is_instance_valid(e) and e.global_position.distance_squared_to(p.global_position) < combat_radius_sq:
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
