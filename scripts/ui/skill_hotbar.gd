# Skill hotbar: 4 slots displaying assigned skills, cooldown overlay, key hint
extends Control
class_name SkillHotbar

@export var player_path: NodePath

@onready var slots: Array[Control] = [
	$Slot1, $Slot2, $Slot3, $Slot4
] if has_node("Slot1") else []

var player: Node = null


func _ready() -> void:
	if player_path != NodePath(""):
		player = get_node_or_null(player_path)
	else:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]


func _process(_delta: float) -> void:
	if not player or slots.size() == 0:
		return
	# Early-out: if no skills assigned and no cooldowns active, nothing to do.
	var any_active := false
	for i in min(4, slots.size()):
		if i < player.skills.size() and player.skills[i] != null:
			any_active = true
			break
		if i < player.skill_cooldowns.size() and player.skill_cooldowns[i] > 0.0:
			any_active = true
			break
	if not any_active:
		return
	for i in min(4, slots.size()):
		var slot := slots[i]
		var cd_label: Label = slot.get_node_or_null("Cooldown") as Label
		var name_label: Label = slot.get_node_or_null("SkillName") as Label
		if i < player.skills.size() and player.skills[i] != null:
			var skill = player.skills[i]
			if name_label:
				name_label.text = skill.skill_name
			var cd: float = player.skill_cooldowns[i]
			if cd_label:
				cd_label.text = "" if cd <= 0.0 else "%.1f" % cd
		else:
			if name_label:
				name_label.text = "—"
			if cd_label:
				cd_label.text = ""
