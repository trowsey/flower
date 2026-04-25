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
