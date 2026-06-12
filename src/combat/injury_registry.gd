class_name InjuryRegistry

const InjuryDataScript := preload("res://src/combat/injury_data.gd")

const CONCUSSION_ID: String = "concussion"
const DEEP_WOUND_ID: String = "deep_wound"


static func get_injury(injury_id: String):
	var definitions := _get_definitions()
	assert(definitions.has(injury_id), "InjuryRegistry: unknown injury %s" % injury_id)
	return InjuryDataScript.create(definitions[injury_id])


static func get_all_injury_ids() -> Array[String]:
	var result: Array[String] = []
	for injury_id: String in _get_definitions().keys():
		result.append(injury_id)
	return result


static func get_melee_skill_modifier(injury_ids: Array[String]) -> int:
	var modifier := 0
	for injury_id: String in injury_ids:
		modifier += get_injury(injury_id).stat_modifiers.get("melee_skill", 0) as int
	return modifier


static func get_ranged_skill_modifier(injury_ids: Array[String]) -> int:
	var modifier := 0
	for injury_id: String in injury_ids:
		modifier += get_injury(injury_id).stat_modifiers.get("ranged_skill", 0) as int
	return modifier


static func get_melee_defense_modifier(injury_ids: Array[String]) -> int:
	var modifier := 0
	for injury_id: String in injury_ids:
		modifier += get_injury(injury_id).stat_modifiers.get("melee_defense", 0) as int
	return modifier


static func get_ranged_defense_modifier(injury_ids: Array[String]) -> int:
	var modifier := 0
	for injury_id: String in injury_ids:
		modifier += get_injury(injury_id).stat_modifiers.get("ranged_defense", 0) as int
	return modifier


static func _get_definitions() -> Dictionary:
	return {
		CONCUSSION_ID:
		{
			"id": CONCUSSION_ID,
			"display_name": "뇌진탕",
			"body_part": "head",
			"temporary": true,
			"stat_modifiers":
			{
				"melee_skill": -10,
				"ranged_skill": -10,
			},
			"recovery_days_range": Vector2i(2, 4),
		},
		DEEP_WOUND_ID:
		{
			"id": DEEP_WOUND_ID,
			"display_name": "깊은 상처",
			"body_part": "body",
			"temporary": true,
			"stat_modifiers":
			{
				"melee_defense": -5,
				"ranged_defense": -5,
			},
			"recovery_days_range": Vector2i(2, 5),
		},
	}
