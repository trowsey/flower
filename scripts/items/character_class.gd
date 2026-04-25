# CharacterClass — defines a playable character's identity and stat profile.
# A pure data Resource. Construct one of the four canonical classes via the
# static factory methods (e.g. CharacterClass.sarah()).
extends Resource
class_name CharacterClass

enum Id { SARAH, MADDIE, CHAN_XAIC, AIYANA }

@export var id: int = Id.SARAH
@export var display_name: String = ""
@export var archetype: String = ""
@export var description: String = ""

# Base stat values — these become PlayerStats base_* fields when the character
# is selected, before any equipment modifiers apply.
@export var base_health: float = 100.0
@export var base_soul: float = 100.0
@export var base_attack_damage: float = 25.0
@export var base_attack_speed: float = 1.0
@export var base_move_speed: float = 7.0
@export var base_defense: float = 0.0
@export var base_soul_drain_resist: float = 0.0

# Visual color tint for placeholder sprites (until real art exists)
@export var primary_color: Color = Color.WHITE
@export var secondary_color: Color = Color.GRAY

# Signature skill — given to the player on slot 1 at character select
@export var signature_skill_name: String = ""
@export var signature_skill_cost: float = 20.0
@export var signature_skill_cooldown: float = 5.0


static func all() -> Array:
	return [sarah(), maddie(), chan_xaic(), aiyana()]


static func _new_instance() -> CharacterClass:
	# Workaround: when this script is preloaded by an autoload, the class_name
	# registry isn't ready yet, so `CharacterClass.new()` inside factory
	# methods can fail. Going through a small helper that uses get_script()
	# avoids the lookup at parse time.
	var s := load("res://scripts/items/character_class.gd")
	return s.new()


static func by_id(id_value: int) -> CharacterClass:
	match id_value:
		Id.SARAH: return sarah()
		Id.MADDIE: return maddie()
		Id.CHAN_XAIC: return chan_xaic()
		Id.AIYANA: return aiyana()
	return sarah()


static func sarah() -> CharacterClass:
	var c := _new_instance()
	c.id = Id.SARAH
	c.display_name = "Sarah"
	c.archetype = "Bladedancer"
	c.description = "Agile melee. Fast strikes, low health, high crit."
	c.base_health = 80.0
	c.base_soul = 90.0
	c.base_attack_damage = 22.0
	c.base_attack_speed = 1.5
	c.base_move_speed = 8.5
	c.base_defense = 0.0
	c.primary_color = Color(0.2, 0.85, 0.3)  # green hair
	c.secondary_color = Color(0.3, 0.45, 0.85)  # blue dress
	c.signature_skill_name = "Whirling Blade"
	c.signature_skill_cost = 15.0
	c.signature_skill_cooldown = 4.0
	return c


static func maddie() -> CharacterClass:
	var c := _new_instance()
	c.id = Id.MADDIE
	c.display_name = "Maddie"
	c.archetype = "Bruiser"
	c.description = "Heavy melee. Hard punches, high health, slow."
	c.base_health = 160.0
	c.base_soul = 70.0
	c.base_attack_damage = 35.0
	c.base_attack_speed = 0.7
	c.base_move_speed = 6.0
	c.base_defense = 5.0
	c.primary_color = Color(0.95, 0.8, 0.2)  # golden hair
	c.secondary_color = Color(0.85, 0.15, 0.15)  # red outfit
	c.signature_skill_name = "Ground Pound"
	c.signature_skill_cost = 25.0
	c.signature_skill_cooldown = 6.0
	return c


static func chan_xaic() -> CharacterClass:
	var c := _new_instance()
	c.id = Id.CHAN_XAIC
	c.display_name = "Chan Xaic"
	c.archetype = "Soulcaster"
	c.description = "Ranged magic. AOE curses, large soul pool."
	c.base_health = 70.0
	c.base_soul = 150.0
	c.base_attack_damage = 18.0
	c.base_attack_speed = 1.0
	c.base_move_speed = 6.5
	c.base_defense = 0.0
	c.base_soul_drain_resist = 0.25
	c.primary_color = Color(0.1, 0.1, 0.15)  # black hair
	c.secondary_color = Color(0.6, 0.1, 0.1)  # deep red robe
	c.signature_skill_name = "Soul Bolt"
	c.signature_skill_cost = 12.0
	c.signature_skill_cooldown = 1.5
	return c


static func aiyana() -> CharacterClass:
	var c := _new_instance()
	c.id = Id.AIYANA
	c.display_name = "Aiyana"
	c.archetype = "Wardweaver"
	c.description = "Balanced. Wards shield allies, slow enemies."
	c.base_health = 110.0
	c.base_soul = 110.0
	c.base_attack_damage = 24.0
	c.base_attack_speed = 1.0
	c.base_move_speed = 7.0
	c.base_defense = 3.0
	c.primary_color = Color(0.35, 0.2, 0.1)  # dark hair
	c.secondary_color = Color(0.2, 0.7, 0.65)  # turquoise
	c.signature_skill_name = "Ward Pulse"
	c.signature_skill_cost = 20.0
	c.signature_skill_cooldown = 5.0
	return c


func apply_to_stats(stats: PlayerStats) -> void:
	stats.base_max_health = base_health
	stats.base_max_soul = base_soul
	stats.base_attack_damage = base_attack_damage
	stats.base_attack_speed = base_attack_speed
	stats.base_move_speed = base_move_speed
	stats.base_defense = base_defense
	stats.base_soul_drain_resist = base_soul_drain_resist
	stats.notify_changed()


func make_signature_skill() -> SkillResource:
	var s := SkillResource.new()
	s.skill_name = signature_skill_name
	s.soul_cost = signature_skill_cost
	s.cooldown = signature_skill_cooldown
	s.execute_method = _signature_skill_method()
	return s


func _signature_skill_method() -> String:
	match id:
		Id.SARAH: return "_skill_whirling_blade"
		Id.MADDIE: return "_skill_ground_pound"
		Id.CHAN_XAIC: return "_skill_soul_bolt"
		Id.AIYANA: return "_skill_ward_pulse"
	return ""
