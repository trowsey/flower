# Runner for the multiplayer playthrough autobot.
#
#   godot --headless --script res://scripts/e2e/autobot_play_runner.gd -- --players=1
#   godot --headless --script res://scripts/e2e/autobot_play_runner.gd -- --players=2
#
# Default is 1 player. Exits 0 on all-pass, 1 on any failure.
extends SceneTree


func _initialize() -> void:
	var player_count: int = 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--players="):
			player_count = int(arg.substr("--players=".length()))
	if player_count < 1:
		player_count = 1
	if player_count > 2:
		player_count = 2

	print("[autobot_play_runner] starting (players=%d)" % player_count)

	# Load main scene FIRST. Touching other scripts before main.tscn loads
	# breaks the class_name registry resolution under a custom SceneTree
	# (RunStats / BiomeManager type annotations in main.gd fail to resolve).
	var main_scene := load("res://scenes/main.tscn")
	if main_scene == null:
		printerr("Failed to load main.tscn")
		quit(1)
		return

	# Configure PartyConfig BEFORE instantiating main scene (main._ready
	# reads PartyConfig.slots). PartyConfig is an autoload already on root.
	var party = root.get_node_or_null("PartyConfig")
	if party and player_count == 2:
		# CharacterClass.Id.SARAH = 0, MADDIE = 1
		party.set_two_player(0, 1, -1, 0)
	# 1P uses PartyConfig's default solo slot.

	var inst: Node = main_scene.instantiate()
	root.add_child(inst)
	# Make the main scene queryable via get_tree().current_scene the same way
	# scenes loaded via change_scene_to_* are.
	current_scene = inst

	var bot_script := load("res://scripts/e2e/autobot_play.gd")
	var bot: Node = bot_script.new()
	bot.name = "AutobotPlay"
	bot.player_count = player_count
	root.add_child(bot)
