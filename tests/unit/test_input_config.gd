extends GutTest
## Tests for Input Configuration — from docs/specs/input-config.md

func test_req1_move_up_action_exists() -> void:
	assert_true(InputMap.has_action("move_up"), "move_up action should exist")


func test_req1_move_down_action_exists() -> void:
	assert_true(InputMap.has_action("move_down"), "move_down action should exist")


func test_req1_move_left_action_exists() -> void:
	assert_true(InputMap.has_action("move_left"), "move_left action should exist")


func test_req1_move_right_action_exists() -> void:
	assert_true(InputMap.has_action("move_right"), "move_right action should exist")


func test_req5_attack_action_exists() -> void:
	assert_true(InputMap.has_action("attack"), "attack action should exist")


func test_req7_interact_action_exists() -> void:
	assert_true(InputMap.has_action("interact"), "interact action should exist")


func test_req8_dodge_action_exists() -> void:
	assert_true(InputMap.has_action("dodge"), "dodge action should exist")


func test_req4_move_up_deadzone() -> void:
	var deadzone := InputMap.action_get_deadzone("move_up")
	assert_eq(deadzone, 0.2, "move_up deadzone should be 0.2")


func test_req4_move_down_deadzone() -> void:
	var deadzone := InputMap.action_get_deadzone("move_down")
	assert_eq(deadzone, 0.2, "move_down deadzone should be 0.2")


func test_req4_move_left_deadzone() -> void:
	var deadzone := InputMap.action_get_deadzone("move_left")
	assert_eq(deadzone, 0.2, "move_left deadzone should be 0.2")


func test_req4_move_right_deadzone() -> void:
	var deadzone := InputMap.action_get_deadzone("move_right")
	assert_eq(deadzone, 0.2, "move_right deadzone should be 0.2")


func test_req5_attack_deadzone() -> void:
	var deadzone := InputMap.action_get_deadzone("attack")
	assert_eq(deadzone, 0.5, "attack deadzone should be 0.5")


func test_req7_interact_deadzone() -> void:
	var deadzone := InputMap.action_get_deadzone("interact")
	assert_eq(deadzone, 0.5, "interact deadzone should be 0.5")


func test_req8_dodge_deadzone() -> void:
	var deadzone := InputMap.action_get_deadzone("dodge")
	assert_eq(deadzone, 0.5, "dodge deadzone should be 0.5")


func test_req2_move_up_has_keyboard_event() -> void:
	var events := InputMap.action_get_events("move_up")
	var has_key := false
	for event in events:
		if event is InputEventKey:
			has_key = true
			break
	assert_true(has_key, "move_up should have a keyboard binding")


func test_req3_move_up_has_joypad_event() -> void:
	var events := InputMap.action_get_events("move_up")
	var has_joy := false
	for event in events:
		if event is InputEventJoypadMotion:
			has_joy = true
			break
	assert_true(has_joy, "move_up should have a joypad binding")


func test_req2_move_down_has_keyboard_event() -> void:
	var events := InputMap.action_get_events("move_down")
	var has_key := false
	for event in events:
		if event is InputEventKey:
			has_key = true
			break
	assert_true(has_key, "move_down should have a keyboard binding")


func test_req2_move_left_has_keyboard_event() -> void:
	var events := InputMap.action_get_events("move_left")
	var has_key := false
	for event in events:
		if event is InputEventKey:
			has_key = true
			break
	assert_true(has_key, "move_left should have a keyboard binding")


func test_req2_move_right_has_keyboard_event() -> void:
	var events := InputMap.action_get_events("move_right")
	var has_key := false
	for event in events:
		if event is InputEventKey:
			has_key = true
			break
	assert_true(has_key, "move_right should have a keyboard binding")


func test_req5_attack_has_joypad_button() -> void:
	var events := InputMap.action_get_events("attack")
	var has_joy := false
	for event in events:
		if event is InputEventJoypadButton:
			has_joy = true
			break
	assert_true(has_joy, "attack should have a joypad button binding")


func test_req9_movement_device_agnostic() -> void:
	# All movement events should use device -1 (any device)
	for action_name in ["move_up", "move_down", "move_left", "move_right"]:
		var events := InputMap.action_get_events(action_name)
		for event in events:
			assert_eq(event.device, -1, "%s event should use device -1 (any)" % action_name)
