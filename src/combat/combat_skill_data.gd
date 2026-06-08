class_name CombatSkillData
extends RefCounted

var id: String = ""
var display_name: String = ""
var action_point_cost: int = 0
var fatigue_cost: int = 0
var attack_range: int = 1
var hit_modifier: int = 0
var damage_percent: int = 100
var armor_damage_percent: int = 100
var armor_penetration_modifier: int = 0
var head_hit_modifier: int = 0
var tags: Array[String] = []


static func create(data: Dictionary):
	var skill = new()
	skill.id = data.get("id", "")
	skill.display_name = data.get("display_name", "")
	skill.action_point_cost = data.get("action_point_cost", 0)
	skill.fatigue_cost = data.get("fatigue_cost", 0)
	skill.attack_range = data.get("attack_range", data.get("range", 1))
	skill.hit_modifier = data.get("hit_modifier", 0)
	skill.damage_percent = data.get("damage_percent", 100)
	skill.armor_damage_percent = data.get("armor_damage_percent", 100)
	skill.armor_penetration_modifier = data.get("armor_penetration_modifier", 0)
	skill.head_hit_modifier = data.get("head_hit_modifier", 0)
	skill.tags.assign(data.get("tags", []))
	return skill


static func basic_attack():
	return create(
		{
			"id": "basic_attack",
			"display_name": "기본 공격",
			"action_point_cost": 4,
			"fatigue_cost": 30,
			"attack_range": 1,
			"hit_modifier": 0,
			"damage_percent": 100,
			"armor_damage_percent": 100,
			"armor_penetration_modifier": 0,
			"head_hit_modifier": 0,
			"tags": ["melee"],
		}
	)
