extends GutTest

const SettingsScript = preload("res://scripts/settings.gd")


func before_each() -> void:
	# Reset config between tests
	if FileAccess.file_exists(SettingsScript.PATH):
		DirAccess.remove_absolute(SettingsScript.PATH)


func test_default_volume_is_zero_db() -> void:
	assert_eq(SettingsScript.get_master_volume(), 0.0)


func test_default_fullscreen_is_false() -> void:
	assert_false(SettingsScript.get_fullscreen())


func test_set_volume_persists() -> void:
	SettingsScript.set_master_volume(-12.0)
	assert_almost_eq(SettingsScript.get_master_volume(), -12.0, 0.01)


func test_volume_is_clamped() -> void:
	SettingsScript.set_master_volume(-999.0)
	assert_gte(SettingsScript.get_master_volume(), -40.0)
	SettingsScript.set_master_volume(999.0)
	assert_lte(SettingsScript.get_master_volume(), 6.0)


func test_set_fullscreen_persists() -> void:
	SettingsScript.set_fullscreen(true)
	assert_true(SettingsScript.get_fullscreen())
	SettingsScript.set_fullscreen(false)
	assert_false(SettingsScript.get_fullscreen())


func test_music_volume_persists() -> void:
	SettingsScript.set_music_volume(-5.0)
	assert_almost_eq(SettingsScript.get_music_volume(), -5.0, 0.01)


func test_sfx_volume_persists() -> void:
	SettingsScript.set_sfx_volume(-3.0)
	assert_almost_eq(SettingsScript.get_sfx_volume(), -3.0, 0.01)


func test_vsync_persists() -> void:
	SettingsScript.set_vsync(false)
	assert_false(SettingsScript.get_vsync())
	SettingsScript.set_vsync(true)
	assert_true(SettingsScript.get_vsync())


func test_camera_shake_clamped() -> void:
	SettingsScript.set_camera_shake(-5.0)
	assert_gte(SettingsScript.get_camera_shake(), 0.0)
	SettingsScript.set_camera_shake(99.0)
	assert_lte(SettingsScript.get_camera_shake(), 2.0)


func test_damage_numbers_persists() -> void:
	SettingsScript.set_damage_numbers(false)
	assert_false(SettingsScript.get_damage_numbers())


func test_loot_magnet_radius_persists() -> void:
	SettingsScript.set_loot_magnet_radius(5.0)
	assert_almost_eq(SettingsScript.get_loot_magnet_radius(), 5.0, 0.01)


func test_reset_to_defaults_restores_values() -> void:
	SettingsScript.set_master_volume(-20.0)
	SettingsScript.set_fullscreen(true)
	SettingsScript.reset_to_defaults()
	assert_eq(SettingsScript.get_master_volume(), 0.0)
	assert_false(SettingsScript.get_fullscreen())
