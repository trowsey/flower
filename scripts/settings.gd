# Settings — persistent user preferences (volume, fullscreen, vsync, gameplay).
# Loaded from user://settings.cfg on demand. Static-style helpers; no autoload
# needed — the pause menu and main scene both call load_and_apply().
extends Node
class_name Settings

const PATH := "user://settings.cfg"

const DEFAULTS := {
	"audio": {
		"master_db": 0.0,
		"music_db": 0.0,
		"sfx_db": 0.0,
	},
	"display": {
		"fullscreen": false,
		"vsync": true,
		"camera_shake": 1.0,
	},
	"gameplay": {
		"damage_numbers": true,
		"loot_magnet_radius": 3.0,
	},
}


static func load_config() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(PATH)  # OK if missing — empty config
	return cfg


static func save_config(cfg: ConfigFile) -> void:
	cfg.save(PATH)


static func _get_value(section: String, key: String):
	return load_config().get_value(section, key, DEFAULTS[section][key])


static func _set_value(section: String, key: String, value) -> void:
	var cfg := load_config()
	cfg.set_value(section, key, value)
	save_config(cfg)


# --- Audio ---

static func get_master_volume() -> float:
	return _get_value("audio", "master_db") as float


static func set_master_volume(db: float) -> void:
	_set_value("audio", "master_db", clamp(db, -40.0, 6.0))
	_apply_volume_bus("Master", db)


static func get_music_volume() -> float:
	return _get_value("audio", "music_db") as float


static func set_music_volume(db: float) -> void:
	_set_value("audio", "music_db", clamp(db, -40.0, 6.0))
	_apply_volume_bus("Music", db)


static func get_sfx_volume() -> float:
	return _get_value("audio", "sfx_db") as float


static func set_sfx_volume(db: float) -> void:
	_set_value("audio", "sfx_db", clamp(db, -40.0, 6.0))
	_apply_volume_bus("SFX", db)


# --- Display ---

static func get_fullscreen() -> bool:
	return _get_value("display", "fullscreen") as bool


static func set_fullscreen(on: bool) -> void:
	_set_value("display", "fullscreen", on)
	_apply_fullscreen(on)


static func get_vsync() -> bool:
	return _get_value("display", "vsync") as bool


static func set_vsync(on: bool) -> void:
	_set_value("display", "vsync", on)
	_apply_vsync(on)


static func get_camera_shake() -> float:
	return _get_value("display", "camera_shake") as float


static func set_camera_shake(scale: float) -> void:
	_set_value("display", "camera_shake", clamp(scale, 0.0, 2.0))


# --- Gameplay ---

static func get_damage_numbers() -> bool:
	return _get_value("gameplay", "damage_numbers") as bool


static func set_damage_numbers(on: bool) -> void:
	_set_value("gameplay", "damage_numbers", on)


static func get_loot_magnet_radius() -> float:
	return _get_value("gameplay", "loot_magnet_radius") as float


static func set_loot_magnet_radius(r: float) -> void:
	_set_value("gameplay", "loot_magnet_radius", clamp(r, 1.0, 6.0))


# --- Reset / apply-on-load ---

static func reset_to_defaults() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)
	load_and_apply()


static func load_and_apply() -> void:
	_apply_volume_bus("Master", get_master_volume())
	_apply_volume_bus("Music", get_music_volume())
	_apply_volume_bus("SFX", get_sfx_volume())
	_apply_fullscreen(get_fullscreen())
	_apply_vsync(get_vsync())


static func _apply_volume_bus(bus_name: String, db: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, db)


static func _apply_fullscreen(on: bool) -> void:
	if Engine.is_editor_hint():
		return
	if on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


static func _apply_vsync(on: bool) -> void:
	if Engine.is_editor_hint():
		return
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if on else DisplayServer.VSYNC_DISABLED
	)
