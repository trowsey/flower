## Regression tests for enemy hit-flash + demon latch lifecycle.
extends GutTest


func _make_enemy() -> CharacterBody3D:
	var script := load("res://scripts/enemies/enemy_base.gd")
	var e := CharacterBody3D.new()
	e.set_script(script)
	add_child_autofree(e)
	# Give it a mesh so the hit-flash code path runs
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	# Surface material so the duplicate-on-flash path triggers
	var src_mat := StandardMaterial3D.new()
	src_mat.albedo_color = Color(0.1, 0.2, 0.3)
	mi.mesh.surface_set_material(0, src_mat)
	e.add_child(mi)
	return e


func test_hit_flash_clears_material_override_when_no_original():
	var e := _make_enemy()
	await get_tree().process_frame
	var mi: MeshInstance3D = e.get_child(0)
	assert_null(mi.material_override, "precondition: no override")
	# Activate flash — should duplicate and tint
	e._apply_hit_flash_modulate(true)
	assert_not_null(mi.material_override, "flash should set override")
	# Deactivate — must restore to null (the original state), not leave it red
	e._apply_hit_flash_modulate(false)
	assert_null(mi.material_override,
		"after flash ends, material_override must be restored to null")


func test_hit_flash_restores_pre_existing_material_override():
	var e := _make_enemy()
	await get_tree().process_frame
	var mi: MeshInstance3D = e.get_child(0)
	var orig := StandardMaterial3D.new()
	orig.albedo_color = Color(0.5, 0.5, 0.5)
	mi.material_override = orig
	e._apply_hit_flash_modulate(true)
	# Modulate may or may not duplicate (override already set), but restore must
	# bring back the same instance we put in.
	e._apply_hit_flash_modulate(false)
	assert_eq(mi.material_override, orig,
		"original material_override must be restored verbatim")


func test_demon_manager_clears_stale_freed_demon_reference():
	var dm = get_node("/root/DemonManager")
	assert_not_null(dm, "DemonManager autoload available")
	# Force a stale latch reference (simulates a demon being freed
	# without going through release_latch — e.g. wave wipe).
	var fake := Node3D.new()
	add_child(fake)
	dm._latched_demon = fake
	fake.queue_free()
	await get_tree().process_frame
	# Now another demon should be able to latch.
	assert_true(dm.is_latch_available(),
		"stale freed-demon reference must not block new latches")
	# Reset for other tests
	dm._latched_demon = null
	dm._latched_target = null


func test_demon_releases_latch_on_lethal_hit():
	# A latched demon that takes lethal damage must release the global
	# DemonManager lock so the next demon can latch.
	var dm = get_node("/root/DemonManager")
	dm._latched_demon = null
	dm._latched_target = null

	var demon_script := load("res://scripts/enemies/demon_base.gd")
	var demon: CharacterBody3D = CharacterBody3D.new()
	demon.set_script(demon_script)
	add_child_autofree(demon)
	await get_tree().process_frame

	# Stub a target with begin/end_soul_drain
	var target := Node3D.new()
	var stub_script := GDScript.new()
	stub_script.source_code = (
		"extends Node3D\n"
		+ "var drained := false\n"
		+ "func begin_soul_drain(_d): drained = true; return true\n"
		+ "func end_soul_drain(): drained = false\n"
	)
	stub_script.reload()
	target.set_script(stub_script)
	add_child_autofree(target)

	# Force latch
	demon.demon_state = demon.DemonState.LATCHED
	dm._latched_demon = demon
	dm._latched_target = target

	# Lethal damage
	demon.take_damage(99999.0)
	assert_false(demon.alive, "demon should be dead")
	assert_true(dm.is_latch_available(),
		"latch must be released even when killed mid-latch")
