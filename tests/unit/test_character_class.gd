extends GutTest

const CharacterClassScript = preload("res://scripts/items/character_class.gd")
const PlayerStatsScript = preload("res://scripts/items/player_stats.gd")


func test_all_returns_four_classes() -> void:
	var classes: Array = CharacterClassScript.all()
	assert_eq(classes.size(), 4, "There should be exactly 4 playable characters")


func test_all_classes_have_unique_ids() -> void:
	var ids: Array = []
	for c in CharacterClassScript.all():
		assert_false(ids.has(c.id), "duplicate id %s" % c.id)
		ids.append(c.id)


func test_each_class_has_distinct_archetype_and_name() -> void:
	var names: Array = []
	var archetypes: Array = []
	for c in CharacterClassScript.all():
		assert_false(c.display_name.is_empty(), "missing name")
		assert_false(c.archetype.is_empty(), "missing archetype")
		assert_false(names.has(c.display_name), "duplicate name")
		assert_false(archetypes.has(c.archetype), "duplicate archetype")
		names.append(c.display_name)
		archetypes.append(c.archetype)


func test_by_id_round_trips() -> void:
	for c in CharacterClassScript.all():
		var fetched: Resource = CharacterClassScript.by_id(c.id)
		assert_eq(fetched.id, c.id)
		assert_eq(fetched.display_name, c.display_name)


func test_factory_methods_return_correct_class() -> void:
	assert_eq(CharacterClassScript.sarah().id, CharacterClassScript.Id.SARAH)
	assert_eq(CharacterClassScript.maddie().id, CharacterClassScript.Id.MADDIE)
	assert_eq(CharacterClassScript.chan_xaic().id, CharacterClassScript.Id.CHAN_XAIC)
	assert_eq(CharacterClassScript.aiyana().id, CharacterClassScript.Id.AIYANA)


func test_apply_to_stats_overwrites_base_values() -> void:
	var stats: Resource = PlayerStatsScript.new()
	var maddie: Resource = CharacterClassScript.maddie()
	maddie.apply_to_stats(stats)
	assert_eq(stats.base_max_health, maddie.base_health)
	assert_eq(stats.base_max_soul, maddie.base_soul)
	assert_almost_eq(stats.base_attack_damage, maddie.base_attack_damage, 0.01)
	assert_almost_eq(stats.base_move_speed, maddie.base_move_speed, 0.01)


func test_make_signature_skill_returns_resource() -> void:
	var sk = CharacterClassScript.sarah().make_signature_skill()
	assert_not_null(sk, "signature skill must be returned")


func test_sarah_is_fast_low_hp() -> void:
	var s: Resource = CharacterClassScript.sarah()
	var m: Resource = CharacterClassScript.maddie()
	assert_gt(s.base_move_speed, m.base_move_speed, "Sarah should outrun Maddie")
	assert_lt(s.base_health, m.base_health, "Sarah should be more fragile than Maddie")


func test_chan_xaic_high_soul() -> void:
	var c: Resource = CharacterClassScript.chan_xaic()
	var m: Resource = CharacterClassScript.maddie()
	assert_gt(c.base_soul, m.base_soul, "Soulcaster should have more soul/mana than the bruiser")
