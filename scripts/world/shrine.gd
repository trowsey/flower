# Shrine — interactive area. First player to step in gets a temporary buff.
extends Area3D
class_name Shrine

signal activated(player: Node3D, buff_id: String)

const BUFF_DURATION := 20.0
const BUFFS := [
	{"id": "swift", "name": "Swift", "mods": {"move_speed_bonus": 2.0}},
	{"id": "wrath", "name": "Wrath", "mods": {"attack_damage_flat": 15.0}},
	{"id": "fortune", "name": "Fortune", "mods": {"crit_chance_bonus": 0.25}},
	{"id": "iron", "name": "Iron", "mods": {"defense_flat": 5.0}},
]

var buff: Dictionary = {}
var used: bool = false
var _mesh: MeshInstance3D
var _light: OmniLight3D


func _ready() -> void:
	add_to_group("shrines")
	collision_layer = 0
	collision_mask = 2
	buff = BUFFS.pick_random()
	_build_visual()
	body_entered.connect(_on_body_entered)


func _build_visual() -> void:
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.5
	shape.shape = sphere
	add_child(shape)
	_mesh = MeshInstance3D.new()
	var pillar := CylinderMesh.new()
	pillar.top_radius = 0.4
	pillar.bottom_radius = 0.6
	pillar.height = 1.6
	_mesh.mesh = pillar
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.75, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.3)
	mat.emission_energy_multiplier = 1.5
	_mesh.material_override = mat
	_mesh.position.y = 0.8
	add_child(_mesh)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.9, 0.3)
	_light.omni_range = 6.0
	_light.position.y = 1.5
	add_child(_light)


func _on_body_entered(body: Node3D) -> void:
	if used or not body.is_in_group("player"):
		return
	used = true
	if body.has_method("apply_temp_buff"):
		body.apply_temp_buff(buff.id, buff.mods, BUFF_DURATION)
	activated.emit(body, buff.id)
	# Fade visual
	if _mesh:
		var tw := create_tween()
		tw.tween_property(_mesh, "modulate", Color(0.3, 0.3, 0.3, 1), 0.4)
	if _light:
		_light.light_energy = 0.0
