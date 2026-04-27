extends "res://scripts/world/pickup_base.gd"
class_name ItemPickup

var item: ItemResource = null
var _beam: MeshInstance3D = null


func set_item(i: ItemResource) -> void:
	item = i
	_apply_rarity_visual()


func _apply_rarity_visual() -> void:
	if item == null:
		return
	var color: Color = ItemResource.rarity_color(item.rarity)
	# Tint the existing mesh
	var mesh := get_node_or_null("Mesh") as MeshInstance3D
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.5 if item.rarity >= ItemResource.Rarity.RARE else 0.6
		mesh.material_override = mat
	# Add a vertical beam for RARE and up
	if item.rarity >= ItemResource.Rarity.RARE and _beam == null:
		_beam = MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.05
		cyl.bottom_radius = 0.05
		cyl.height = 6.0
		_beam.mesh = cyl
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = Color(color.r, color.g, color.b, 0.5)
		bmat.emission_enabled = true
		bmat.emission = color
		bmat.emission_energy_multiplier = 2.0
		bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_beam.material_override = bmat
		_beam.position = Vector3(0, 3.0, 0)
		add_child(_beam)


func collect(player: Node3D) -> void:
	if player and player.has_method("add_item") and item:
		if player.add_item(item):
			collected.emit(player)
			queue_free()
