class_name CombatSkillRegistry
extends RefCounted

const CombatSkillDataScript := preload("res://src/combat/combat_skill_data.gd")

const BASIC_ATTACK_ID: String = "basic_attack"
const SPEAR_THRUST_ID: String = "spear_thrust"
const MACE_STRIKE_ID: String = "mace_strike"
const RANGED_SHOT_ID: String = "ranged_shot"
const SHIELDWALL_ID: String = "shieldwall"
const WAIT_ID: String = "wait"
const RECOVER_ID: String = "recover"
const FOOTWORK_ID: String = "footwork"


static func get_skill(skill_id: String):
	var definitions := _get_definitions()
	assert(definitions.has(skill_id), "CombatSkillRegistry: unknown skill id %s" % skill_id)
	return CombatSkillDataScript.create(definitions[skill_id])


static func has_skill(skill_id: String) -> bool:
	return _get_definitions().has(skill_id)


static func get_all_skill_ids() -> Array[String]:
	var result: Array[String] = []
	for skill_id: String in _get_definitions().keys():
		result.append(skill_id)
	return result


static func get_all_skills() -> Array:
	var result: Array = []
	for skill_id: String in get_all_skill_ids():
		result.append(get_skill(skill_id))
	return result


static func _get_definitions() -> Dictionary:
	return {
		BASIC_ATTACK_ID:
		{
			"id": BASIC_ATTACK_ID,
			"display_name": "기본 공격",
			"action_point_cost": 4,
			"fatigue_cost": 30,
			"attack_range": 1,
			"damage_percent": 100,
			"armor_damage_percent": 100,
			"tags": ["melee", "one_handed"],
		},
		SPEAR_THRUST_ID:
		{
			"id": SPEAR_THRUST_ID,
			"display_name": "창 찌르기",
			"action_point_cost": 4,
			"fatigue_cost": 25,
			"attack_range": 1,
			"hit_modifier": 10,
			"damage_percent": 90,
			"armor_damage_percent": 80,
			"tags": ["melee", "spear", "thrust"],
		},
		MACE_STRIKE_ID:
		{
			"id": MACE_STRIKE_ID,
			"display_name": "둔기 타격",
			"action_point_cost": 4,
			"fatigue_cost": 35,
			"attack_range": 1,
			"hit_modifier": -5,
			"damage_percent": 110,
			"armor_damage_percent": 120,
			"armor_penetration_modifier": 10,
			"tags": ["melee", "mace", "blunt"],
		},
		RANGED_SHOT_ID:
		{
			"id": RANGED_SHOT_ID,
			"display_name": "원거리 사격",
			"action_point_cost": 4,
			"fatigue_cost": 20,
			"attack_range": 6,
			"hit_modifier": -5,
			"damage_percent": 90,
			"armor_damage_percent": 70,
			"tags": ["ranged", "bow"],
		},
		SHIELDWALL_ID:
		{
			"id": SHIELDWALL_ID,
			"display_name": "방패벽",
			"action_point_cost": 4,
			"fatigue_cost": 20,
			"attack_range": 0,
			"tags": ["defense", "shield", "status"],
		},
		WAIT_ID:
		{
			"id": WAIT_ID,
			"display_name": "대기",
			"action_point_cost": 0,
			"fatigue_cost": 0,
			"attack_range": 0,
			"tags": ["utility", "wait"],
		},
		RECOVER_ID:
		{
			"id": RECOVER_ID,
			"display_name": "회복",
			"action_point_cost": 9,
			"fatigue_cost": 0,
			"fatigue_recovery": 30,
			"attack_range": 0,
			"tags": ["utility", "recover"],
		},
		FOOTWORK_ID:
		{
			"id": FOOTWORK_ID,
			"display_name": "발놀림",
			"action_point_cost": 3,
			"fatigue_cost": 25,
			"attack_range": 0,
			"tags": ["utility", "movement", "zoc_ignore"],
		},
	}
