# Headless E2E autobot — programmatically plays the game and validates state.
#
# Run via:
#   godot --headless --path . scenes/main.tscn --autobot
# OR:
#   godot --headless --script res://scripts/e2e/autobot_runner.gd
#
# Records screenshots at checkpoints to user://e2e_screenshots/ and writes a
# pass/fail report. Exits with code 0 on success, 1 on failure.
extends Node
class_name Autobot

signal autobot_finished(passed: bool, results: Array)

const STEP_INTERVAL := 0.1
const SCREENSHOT_DIR := "user://e2e_screenshots/"

var player: Node = null
var results: Array = []  # {name: String, passed: bool, message: String}
var _step: int = 0
var _checkpoints: Array = []
var _failed: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCREENSHOT_DIR))
	# Wait one frame for scene to settle
	await get_tree().process_frame
	await get_tree().process_frame
	_resolve_player()
	_build_checkpoints()
	_run()


func _resolve_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


func _build_checkpoints() -> void:
	_checkpoints = [
		{"name": "player_exists", "fn": "_check_player_exists"},
		{"name": "player_has_full_health", "fn": "_check_full_health"},
		{"name": "player_has_full_soul", "fn": "_check_full_soul"},
		{"name": "player_can_move", "fn": "_test_movement"},
		{"name": "player_can_attack", "fn": "_test_attack"},
		{"name": "take_damage_works", "fn": "_test_damage"},
		{"name": "gold_pickup_works", "fn": "_test_gold"},
		{"name": "xp_and_levelup_works", "fn": "_test_levelup"},
		{"name": "inventory_add_equip", "fn": "_test_inventory"},
		{"name": "soul_drain_state_machine", "fn": "_test_soul_drain"},
	]


func _run() -> void:
	for cp in _checkpoints:
		var fn: String = cp.fn
		var name: String = cp.name
		var passed: bool = false
		var msg: String = ""
		if has_method(fn):
			var r = await call(fn)
			if r is Dictionary:
				passed = r.get("passed", false)
				msg = r.get("message", "")
			else:
				passed = bool(r)
		results.append({"name": name, "passed": passed, "message": msg})
		if not passed:
			_failed = true
		_screenshot(name)
	_emit_report()
	autobot_finished.emit(not _failed, results)
	if not Engine.is_editor_hint() and DisplayServer.get_name() != "headless":
		pass
	# Exit with code
	get_tree().quit(0 if not _failed else 1)


func _screenshot(label: String) -> void:
	# Skip in headless server (dummy renderer can't read viewport texture)
	if DisplayServer.get_name() == "headless":
		_step += 1
		return
	var img := get_viewport().get_texture().get_image()
	if img == null:
		_step += 1
		return
	var path := SCREENSHOT_DIR + "%02d_%s.png" % [_step, label]
	img.save_png(ProjectSettings.globalize_path(path))
	_step += 1


func _emit_report() -> void:
	print("\n========== E2E AUTOBOT REPORT ==========")
	var passed_count: int = 0
	for r in results:
		var status: String = "PASS" if r.passed else "FAIL"
		print("  [%s] %s %s" % [status, r.name, ("- " + r.message) if r.message != "" else ""])
		if r.passed: passed_count += 1
	print("\n%d / %d checks passed" % [passed_count, results.size()])
	print("========================================\n")


# ---- Checkpoints ----

func _check_player_exists() -> Dictionary:
	if player == null:
		return {"passed": false, "message": "No player node in 'player' group"}
	return {"passed": true, "message": ""}


func _check_full_health() -> Dictionary:
	if player == null:
		return {"passed": false, "message": "no player"}
	if player.health < player.stats.max_health() - 0.01:
		return {"passed": false, "message": "health=%f max=%f" % [player.health, player.stats.max_health()]}
	return {"passed": true}


func _check_full_soul() -> Dictionary:
	if player == null:
		return {"passed": false, "message": "no player"}
	if player.soul < player.stats.max_soul() - 0.01:
		return {"passed": false, "message": "soul=%f" % player.soul}
	return {"passed": true}


func _test_movement() -> Dictionary:
	if player == null:
		return {"passed": false, "message": "no player"}
	var start_pos: Vector3 = player.global_position
	# Use Input.action_press to drive the real movement code path
	Input.action_press("move_right", 1.0)
	for _i in 20:
		await get_tree().physics_frame
	Input.action_release("move_right")
	var moved: bool = player.global_position.distance_to(start_pos) > 0.1
	return {"passed": moved, "message": "" if moved else "did not move (start=%s end=%s)" % [start_pos, player.global_position]}


func _test_attack() -> Dictionary:
	if player == null:
		return {"passed": false, "message": "no player"}
	var initial_combo: int = player._combo_stage
	player._start_attack()
	await get_tree().create_timer(0.05).timeout
	var advanced: bool = player._combo_stage > initial_combo
	# Wait for attack to complete
	await get_tree().create_timer(0.6).timeout
	return {"passed": advanced, "message": "" if advanced else "combo did not advance"}


func _test_damage() -> Dictionary:
	if player == null:
		return {"passed": false, "message": "no player"}
	var hp_before: float = player.health
	player.take_damage(10.0)
	var diff: float = hp_before - player.health
	if diff <= 0.0:
		return {"passed": false, "message": "no damage"}
	return {"passed": true, "message": "lost %.1f HP" % diff}


func _test_gold() -> Dictionary:
	if player == null:
		return {"passed": false, "message": "no player"}
	var before: int = player.gold
	player.add_gold(50)
	if player.gold != before + 50:
		return {"passed": false, "message": "gold did not increase"}
	if not player.spend_gold(20):
		return {"passed": false, "message": "spend failed"}
	return {"passed": player.gold == before + 30}


func _test_levelup() -> Dictionary:
	if player == null:
		return {"passed": false, "message": "no player"}
	var lvl_before: int = player.stats.level
	# Big XP push
	player.add_xp(10000.0)
	var leveled: bool = player.stats.level > lvl_before
	return {"passed": leveled, "message": "lvl %d -> %d" % [lvl_before, player.stats.level]}


func _test_inventory() -> Dictionary:
	if player == null:
		return {"passed": false, "message": "no player"}
	var weapon := ItemFactory.make_random(ItemResource.ItemType.WEAPON, ItemResource.Rarity.RARE)
	if not player.add_item(weapon):
		return {"passed": false, "message": "could not add item"}
	# Find slot
	var slot_idx := -1
	for i in player.inventory.slots.size():
		if player.inventory.slots[i] == weapon:
			slot_idx = i
			break
	if slot_idx < 0:
		return {"passed": false, "message": "item not in inventory"}
	if not player.equip_item(slot_idx):
		return {"passed": false, "message": "equip failed"}
	if player.equipment.get_equipped(ItemResource.ItemType.WEAPON) != weapon:
		return {"passed": false, "message": "weapon not equipped"}
	return {"passed": true, "message": "equipped %s" % weapon.item_name}


func _test_soul_drain() -> Dictionary:
	if player == null:
		return {"passed": false, "message": "no player"}
	# Create fake demon node — attach to player to ensure valid parent
	var demon := Node3D.new()
	demon.name = "FakeDemon"
	var parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	parent.add_child(demon)
	var ok: bool = player.begin_soul_drain(demon)
	if not ok:
		demon.queue_free()
		return {"passed": false, "message": "begin_soul_drain returned false"}
	if player.state != player.PlayerState.BEING_DRAINED:
		demon.queue_free()
		return {"passed": false, "message": "state not BEING_DRAINED"}
	var soul_before: float = player.soul
	for _i in 30:
		await get_tree().physics_frame
	var drained: bool = player.soul < soul_before
	player.end_soul_drain()
	demon.queue_free()
	if player.state != player.PlayerState.NORMAL:
		return {"passed": false, "message": "did not return to NORMAL"}
	return {"passed": drained, "message": ("drained %.2f" % (soul_before - player.soul)) if drained else "soul did not decrease"}
