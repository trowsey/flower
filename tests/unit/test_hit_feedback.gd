extends GutTest

const HFScript := preload("res://scripts/vfx/hit_feedback.gd")


func _make_hf() -> Node:
	var hf = HFScript.new()
	add_child_autofree(hf)
	return hf


func test_explosion_method_exists_and_callable() -> void:
	var hf = _make_hf()
	assert_true(hf.has_method("explosion"))
	# Must not crash with various radii
	hf.explosion(Vector3.ZERO, 1.0)
	hf.explosion(Vector3(1, 0, 1), 8.0)


func test_explosion_emits_camera_shake() -> void:
	var hf = _make_hf()
	watch_signals(hf)
	hf.explosion(Vector3.ZERO, 3.0)
	assert_signal_emitted(hf, "request_camera_shake")


func test_explosion_emits_hit_stop() -> void:
	var hf = _make_hf()
	watch_signals(hf)
	hf.explosion(Vector3.ZERO, 3.0)
	assert_signal_emitted(hf, "request_hit_stop")


func test_enemy_hit_signature_critical_optional() -> void:
	var hf = _make_hf()
	# Both 3-arg and 4-arg call sites must work
	hf.enemy_hit(Vector3.ZERO, 10.0)
	hf.enemy_hit(Vector3.ZERO, 10.0, null, true)
	assert_true(hf.has_method("enemy_hit"))
