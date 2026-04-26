extends GutTest


func test_xp_required_increases_with_level() -> void:
	var s := PlayerStats.new()
	var x2 := s.xp_required_for_level(2)
	var x10 := s.xp_required_for_level(10)
	var x20 := s.xp_required_for_level(20)
	assert_gt(x10, x2)
	assert_gt(x20, x10)


func test_xp_curve_smoother_than_old() -> void:
	# At level 20, the smoothed curve should require less than the old 1.2^n curve.
	var s := PlayerStats.new()
	var smoothed := s.xp_required_for_level(20)
	var old_style: float = 100.0 * 19.0 * pow(1.2, 19)
	assert_lt(smoothed, old_style)


func test_xp_required_level_one_is_zero() -> void:
	var s := PlayerStats.new()
	assert_eq(s.xp_required_for_level(1), 0.0)


func test_crit_chance_bonus_starts_zero() -> void:
	var s := PlayerStats.new()
	assert_eq(s.crit_chance_bonus(), 0.0)


func test_crit_chance_bonus_picks_up_modifiers() -> void:
	var s := PlayerStats.new()
	s.set_modifiers({"crit_chance_bonus": 0.15})
	assert_almost_eq(s.crit_chance_bonus(), 0.15, 0.001)
