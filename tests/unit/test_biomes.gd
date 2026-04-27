extends GutTest

const BiomeManagerScript := preload("res://scripts/world/biome_manager.gd")
const BiomeDefScript := preload("res://scripts/world/biome_def.gd")


func test_biome_manager_starts_at_first_biome() -> void:
	var bm: Node = BiomeManagerScript.new()
	add_child_autofree(bm)
	var b = bm.current()
	assert_eq(b.biome_id, "crypt")


func test_biome_rotates_every_five_waves() -> void:
	var bm: Node = BiomeManagerScript.new()
	add_child_autofree(bm)
	for w in range(1, 5):
		bm.notify_wave_cleared(w)
	assert_eq(bm.current().biome_id, "crypt", "still on first biome after 4 waves")
	bm.notify_wave_cleared(5)
	assert_eq(bm.current().biome_id, "cavern")
	bm.notify_wave_cleared(10)
	assert_eq(bm.current().biome_id, "forge")


func test_biome_loops_and_increments_difficulty() -> void:
	var bm: Node = BiomeManagerScript.new()
	add_child_autofree(bm)
	for i in 4:
		bm.notify_wave_cleared(5 * (i + 1))
	assert_eq(bm.current().biome_id, "crypt")
	assert_eq(bm.difficulty_loop, 1)


func test_all_biomes_have_enemy_pools() -> void:
	for b in BiomeDefScript.ALL():
		assert_gt(b.enemy_scenes.size(), 0, "%s has empty pool" % b.biome_id)
