# Settings — persistent user preferences (volume, fullscreen).
# Loaded from user://settings.cfg on demand. Static-style helpers; no autoload
# needed — the pause menu and main scene both call load_and_apply().
extends Node
class_name Settings

const PATH := "user://settings.cfg"


static func load_config() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(PATH)  # OK if missing — empty config
	return cfg


static func save_config(cfg: ConfigFile) -> void:
	cfg.save(PATH)


static func get_master_volume() -> float:
	return load_config().get_value("audio", "master_db", 0.0) as float


static func set_master_volume(db: float) -> void:
	var cfg := load_config()
	cfg.set_value("audio", "master_db", clamp(db, -40.0, 6.0))
	save_config(cfg)
	_apply_volume(db)


static func get_fullscreen() -> bool:
	return load_config().get_value("display", "fullscreen", false) as bool


static func set_fullscreen(on: bool) -> void:
	var cfg := load_config()
	cfg.set_value("display", "fullscreen", on)
	save_config(cfg)
	_apply_fullscreen(on)


static func load_and_apply() -> void:
	_apply_volume(get_master_volume())
	_apply_fullscreen(get_fullscreen())


static func _apply_volume(db: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, db)


static func _apply_fullscreen(on: bool) -> void:
	if Engine.is_editor_hint():
		return
	if on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
