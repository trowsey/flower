## SkillResource — data container for active skills equipped to the hotbar.
extends Resource
class_name SkillResource

@export var skill_name: String = "Unknown"
@export var icon: Texture2D
@export var description: String = ""
@export var cooldown: float = 5.0
@export var soul_cost: float = 0.0
# Multiplier applied to player's attack_damage when the skill deals damage.
# 0.0 means the skill deals no damage (e.g. heals).
@export var damage_multiplier: float = 0.0
@export var radius: float = 3.0
# Flat heal amount for support skills.
@export var heal_amount: float = 0.0
@export var execute_method: String = ""
