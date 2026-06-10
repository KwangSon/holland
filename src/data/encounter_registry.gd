class_name EncounterRegistry

const EncounterDataScript := preload("res://src/data/encounter_data.gd")
const EnemyRegistryScript := preload("res://src/data/enemy_registry.gd")

const BANDIT_SKIRMISH_ID := "bandit_skirmish"
const UNDEAD_SKIRMISH_ID := "undead_skirmish"
const BEAST_SKIRMISH_ID := "beast_skirmish"


static func get_encounter(encounter_id: String):
	var definitions := _get_definitions()
	assert(definitions.has(encounter_id), "EncounterRegistry: unknown encounter %s" % encounter_id)
	return EncounterDataScript.create(definitions[encounter_id])


static func get_all_encounter_ids() -> Array[String]:
	var result: Array[String] = []
	for encounter_id: String in _get_definitions().keys():
		result.append(encounter_id)
	return result


static func _get_definitions() -> Dictionary:
	return {
		BANDIT_SKIRMISH_ID:
		{
			"id": BANDIT_SKIRMISH_ID,
			"display_name": "산적 정찰대",
			"seed": 101,
			"enemy_entries":
			[
				{
					"archetype_id": EnemyRegistryScript.BANDIT_THUG_ID,
					"unit_id": "bandit_thug_1",
					"position": Vector2i(7, 3),
				},
				{
					"archetype_id": EnemyRegistryScript.BANDIT_RAIDER_ID,
					"unit_id": "bandit_raider_1",
					"position": Vector2i(6, 4),
				},
				{
					"archetype_id": EnemyRegistryScript.BANDIT_MARKSMAN_ID,
					"unit_id": "bandit_marksman_1",
					"position": Vector2i(7, 5),
				},
			],
		},
		UNDEAD_SKIRMISH_ID:
		{
			"id": UNDEAD_SKIRMISH_ID,
			"display_name": "언데드 잔당",
			"seed": 202,
			"enemy_entries":
			[
				{
					"archetype_id": EnemyRegistryScript.UNDEAD_ZOMBIE_ID,
					"unit_id": "undead_zombie_1",
					"position": Vector2i(7, 3),
				},
				{
					"archetype_id": EnemyRegistryScript.UNDEAD_SKELETON_ID,
					"unit_id": "undead_skeleton_1",
					"position": Vector2i(6, 4),
				},
			],
		},
		BEAST_SKIRMISH_ID:
		{
			"id": BEAST_SKIRMISH_ID,
			"display_name": "야수 습격",
			"seed": 303,
			"enemy_entries":
			[
				{
					"archetype_id": EnemyRegistryScript.BEAST_WOLF_ID,
					"unit_id": "beast_wolf_1",
					"position": Vector2i(7, 3),
				},
				{
					"archetype_id": EnemyRegistryScript.BEAST_SPIDER_ID,
					"unit_id": "beast_spider_1",
					"position": Vector2i(6, 4),
				},
			],
		},
	}
