class_name EnemyRegistry

const EnemyArchetypeDataScript := preload("res://src/data/enemy_archetype_data.gd")

const BANDIT_THUG_ID := "bandit_thug"
const BANDIT_RAIDER_ID := "bandit_raider"
const BANDIT_MARKSMAN_ID := "bandit_marksman"
const UNDEAD_ZOMBIE_ID := "undead_zombie"
const UNDEAD_SKELETON_ID := "undead_skeleton"
const BEAST_WOLF_ID := "beast_wolf"
const BEAST_SPIDER_ID := "beast_spider"


static func get_archetype(archetype_id: String):
	var definitions := _get_definitions()
	assert(definitions.has(archetype_id), "EnemyRegistry: unknown archetype %s" % archetype_id)
	return EnemyArchetypeDataScript.create(definitions[archetype_id])


static func get_all_archetype_ids() -> Array[String]:
	var result: Array[String] = []
	for archetype_id: String in _get_definitions().keys():
		result.append(archetype_id)
	return result


static func create_unit(archetype_id: String, unit_id: String, position: Vector2i) -> CombatUnit:
	return get_archetype(archetype_id).create_unit(unit_id, position)


static func create_units(entries: Array) -> Array[CombatUnit]:
	var result: Array[CombatUnit] = []
	for i: int in entries.size():
		var entry: Dictionary = entries[i]
		var unit_id: String = entry.get("unit_id", "enemy_%d" % i)
		result.append(create_unit(entry["archetype_id"], unit_id, entry["position"]))
	return result


static func _get_definitions() -> Dictionary:
	return {
		BANDIT_THUG_ID:
		{
			"id": BANDIT_THUG_ID,
			"display_name": "산적 깡패",
			"family": "bandit",
			"skill_ids": [CombatSkillRegistry.BASIC_ATTACK_ID],
			"unit_data": _base_unit(35, 55, 20, 8, 4, 80, 85, 11, 20),
		},
		BANDIT_RAIDER_ID:
		{
			"id": BANDIT_RAIDER_ID,
			"display_name": "산적 약탈자",
			"family": "bandit",
			"skill_ids": [CombatSkillRegistry.BASIC_ATTACK_ID, CombatSkillRegistry.MACE_STRIKE_ID],
			"unit_data": _base_unit(45, 62, 25, 12, 8, 95, 90, 14, 30),
		},
		BANDIT_MARKSMAN_ID:
		{
			"id": BANDIT_MARKSMAN_ID,
			"display_name": "산적 사수",
			"family": "bandit",
			"skill_ids": [CombatSkillRegistry.RANGED_SHOT_ID],
			"unit_data": _ranged_unit(32, 45, 58, 6, 12, 80, 100, 10, 20, 8),
		},
		UNDEAD_ZOMBIE_ID:
		{
			"id": UNDEAD_ZOMBIE_ID,
			"display_name": "되살아난 시체",
			"family": "undead",
			"skill_ids": [CombatSkillRegistry.BASIC_ATTACK_ID],
			"unit_data": _base_unit(55, 50, 10, 2, 0, 120, 45, 12, 10),
		},
		UNDEAD_SKELETON_ID:
		{
			"id": UNDEAD_SKELETON_ID,
			"display_name": "해골 전사",
			"family": "undead",
			"skill_ids": [CombatSkillRegistry.SPEAR_THRUST_ID],
			"unit_data": _base_unit(38, 58, 25, 10, 12, 90, 75, 11, 25),
		},
		BEAST_WOLF_ID:
		{
			"id": BEAST_WOLF_ID,
			"display_name": "굶주린 늑대",
			"family": "beast",
			"skill_ids": [CombatSkillRegistry.BASIC_ATTACK_ID],
			"unit_data": _base_unit(28, 60, 0, 12, 8, 70, 120, 9, 15),
		},
		BEAST_SPIDER_ID:
		{
			"id": BEAST_SPIDER_ID,
			"display_name": "동굴 거미",
			"family": "beast",
			"skill_ids": [CombatSkillRegistry.BASIC_ATTACK_ID],
			"unit_data": _base_unit(34, 55, 5, 8, 10, 75, 105, 10, 20),
		},
	}


static func _base_unit(
	max_hp: int,
	melee_skill: int,
	armor: int,
	melee_defense: int,
	ranged_defense: int,
	max_fatigue: int,
	initiative: int,
	damage: int,
	armor_penetration: int
) -> Dictionary:
	return {
		"max_hp": max_hp,
		"head_armor": floori(float(armor) / 2.0),
		"body_armor": armor,
		"max_action_points": 9,
		"max_fatigue": max_fatigue,
		"morale": 100,
		"resolve": 45,
		"initiative": initiative,
		"melee_skill": melee_skill,
		"ranged_skill": 0,
		"melee_defense": melee_defense,
		"ranged_defense": ranged_defense,
		"damage": damage,
		"armor_penetration": armor_penetration,
		"chance_to_hit_head": 25,
	}


static func _ranged_unit(
	max_hp: int,
	melee_skill: int,
	ranged_skill: int,
	melee_defense: int,
	ranged_defense: int,
	max_fatigue: int,
	initiative: int,
	damage: int,
	armor_penetration: int,
	ammo: int
) -> Dictionary:
	var data := _base_unit(
		max_hp,
		melee_skill,
		15,
		melee_defense,
		ranged_defense,
		max_fatigue,
		initiative,
		damage,
		armor_penetration
	)
	data["ranged_skill"] = ranged_skill
	data["ammo"] = ammo
	data["max_ammo"] = ammo
	return data
