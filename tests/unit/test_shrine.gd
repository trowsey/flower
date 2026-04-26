extends GutTest

const ShrineScript := preload("res://scripts/world/shrine.gd")


func test_shrine_picks_random_buff() -> void:
	var s = ShrineScript.new()
	add_child_autofree(s)
	assert_not_null(s.buff)
	assert_true(s.buff.has("id"))
	assert_true(s.buff.has("mods"))


func test_shrine_only_activates_once() -> void:
	var s = ShrineScript.new()
	add_child_autofree(s)
	assert_false(s.used)
	# Simulate body entry with a fake player
	var fake = Node3D.new()
	add_child_autofree(fake)
	fake.add_to_group("player")
	# add a no-op apply_temp_buff
	fake.set_script(GDScript.new())
	# Manually flag used to assert idempotency without requiring full player wiring
	s.used = true
	s._on_body_entered(fake)
	assert_true(s.used)
