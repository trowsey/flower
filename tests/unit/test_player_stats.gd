extends GutTest
## Tests for PlayerStats Resource

var _stats: PlayerStats


func before_each() -> void:
	_stats = PlayerStats.new()


func test_default_level_is_one() -> void:
	assert_eq(_stats.level, 1)


func test_default_attack_damage() -> void:
	assert_almost_eq(_stats.attack_damage(), 25.0, 0.001)


func test_strength_increases_attack_damage() -> void:
	_stats.strength = 5
	assert_almost_eq(_stats.attack_damage(), 35.0, 0.001)  # 25 + 5*2


func test_modifier_increases_attack_damage() -> void:
	_stats.set_modifiers({"attack_damage_flat": 10.0})
	assert_almost_eq(_stats.attack_damage(), 35.0, 0.001)


func test_xp_levels_up() -> void:
	var levels: Array = _stats.add_xp(10000.0)
	assert_gt(levels.size(), 0, "Should have leveled up")
	assert_gt(_stats.level, 1, "Level should increase")


func test_vitality_increases_max_health() -> void:
	var base_hp: float = _stats.max_health()
	_stats.vitality = 5
	assert_almost_eq(_stats.max_health(), base_hp + 50.0, 0.001)


func test_max_level_cap() -> void:
	_stats.add_xp(1e10)
	assert_eq(_stats.level, _stats.MAX_LEVEL, "Should cap at MAX_LEVEL")
