# E2E runner: launches main scene with the autobot attached.
# Run: godot --headless --script res://scripts/e2e/autobot_runner.gd
extends SceneTree


func _initialize() -> void:
	print("[autobot_runner] starting")
	var main_scene := load("res://scenes/main.tscn")
	if main_scene == null:
		printerr("Failed to load main.tscn")
		quit(1)
		return
	var inst: Node = main_scene.instantiate()
	root.add_child(inst)
	var autobot_script := load("res://scripts/e2e/autobot.gd")
	var bot = autobot_script.new()
	bot.name = "Autobot"
	root.add_child(bot)
