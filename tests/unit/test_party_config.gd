extends GutTest

const CharacterClassScript = preload("res://scripts/items/character_class.gd")


func before_each() -> void:
	PartyConfig.clear()


func after_all() -> void:
	# Restore default so other suites/runs aren't affected
	PartyConfig.set_solo(CharacterClassScript.Id.SARAH)


func test_clear_empties_slots() -> void:
	PartyConfig.set_solo(CharacterClassScript.Id.SARAH)
	PartyConfig.clear()
	assert_eq(PartyConfig.player_count(), 0)


func test_set_solo_creates_one_slot() -> void:
	PartyConfig.set_solo(CharacterClassScript.Id.MADDIE)
	assert_eq(PartyConfig.player_count(), 1)
	var s: Dictionary = PartyConfig.get_slot(0)
	assert_eq(s["character_class_id"], CharacterClassScript.Id.MADDIE)
	assert_eq(s["device_id"], -1, "Solo player should be device -1 (kbd+mouse+joy0)")


func test_set_two_player_creates_two_slots() -> void:
	PartyConfig.set_two_player(
		CharacterClassScript.Id.SARAH,
		CharacterClassScript.Id.AIYANA,
		-1, 1
	)
	assert_eq(PartyConfig.player_count(), 2)
	assert_eq(PartyConfig.get_slot(0)["character_class_id"], CharacterClassScript.Id.SARAH)
	assert_eq(PartyConfig.get_slot(1)["character_class_id"], CharacterClassScript.Id.AIYANA)
	assert_eq(PartyConfig.get_slot(0)["device_id"], -1)
	assert_eq(PartyConfig.get_slot(1)["device_id"], 1)


func test_get_slot_out_of_range_returns_empty() -> void:
	PartyConfig.set_solo(CharacterClassScript.Id.SARAH)
	assert_eq(PartyConfig.get_slot(99), {})
	assert_eq(PartyConfig.get_slot(-1), {})
