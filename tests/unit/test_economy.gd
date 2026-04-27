extends GutTest


func test_sell_value_increases_with_rarity() -> void:
	var common := ItemResource.new()
	common.rarity = ItemResource.Rarity.COMMON
	var legendary := ItemResource.new()
	legendary.rarity = ItemResource.Rarity.LEGENDARY
	assert_gt(legendary.sell_value(), common.sell_value() * 5)


func test_sell_value_scales_with_item_level() -> void:
	var low := ItemResource.new()
	low.rarity = ItemResource.Rarity.RARE
	low.item_level = 1
	var high := ItemResource.new()
	high.rarity = ItemResource.Rarity.RARE
	high.item_level = 10
	assert_gt(high.sell_value(), low.sell_value())


func test_set_pieces_double_sell_value() -> void:
	var plain := ItemResource.new()
	plain.rarity = ItemResource.Rarity.RARE
	var set_piece := ItemResource.new()
	set_piece.rarity = ItemResource.Rarity.RARE
	set_piece.set_id = "berserkers_wrath"
	assert_eq(set_piece.sell_value(), plain.sell_value() * 2)


func test_run_stats_records_damage() -> void:
	var rs = preload("res://scripts/run_stats.gd").new()
	add_child_autofree(rs)
	rs.record_damage_dealt(50.0, false)
	rs.record_damage_dealt(100.0, true)
	rs.record_damage_taken(30.0)
	assert_eq(rs.damage_dealt, 150.0)
	assert_eq(rs.crit_hits, 1)
	assert_eq(rs.damage_taken, 30.0)


func test_run_stats_records_boss_kills() -> void:
	var rs = preload("res://scripts/run_stats.gd").new()
	add_child_autofree(rs)
	rs.record_kill(false, false)
	rs.record_kill(true, false)
	rs.record_kill(true, true)
	assert_eq(rs.kills, 3)
	assert_eq(rs.elite_kills, 2)
	assert_eq(rs.boss_kills, 1)


func test_run_stats_records_legendary_pickup() -> void:
	var rs = preload("res://scripts/run_stats.gd").new()
	add_child_autofree(rs)
	var leg := ItemResource.new()
	leg.rarity = ItemResource.Rarity.LEGENDARY
	rs.record_item_picked(leg)
	assert_eq(rs.items_picked, 1)
	assert_eq(rs.legendaries_found, 1)


func test_run_stats_records_set_pickup() -> void:
	var rs = preload("res://scripts/run_stats.gd").new()
	add_child_autofree(rs)
	var p := ItemResource.new()
	p.rarity = ItemResource.Rarity.RARE
	p.set_id = "berserkers_wrath"
	rs.record_item_picked(p)
	assert_eq(rs.sets_found, 1)
