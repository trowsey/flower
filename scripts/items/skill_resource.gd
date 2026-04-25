## SkillResource — data container for active skills equipped to the hotbar.
extends Resource
class_name SkillResource

@export var skill_name: String = "Unknown"
@export var icon: Texture2D
@export var description: String = ""
@export var cooldown: float = 5.0
@export var soul_cost: float = 0.0
@export var damage: float = 0.0
@export var radius: float = 3.0
@export var execute_method: String = ""
