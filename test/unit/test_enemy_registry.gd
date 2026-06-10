extends GutTest

const EnemyRegistryScript := preload("res://src/data/enemy_registry.gd")
const EncounterRegistryScript := preload("res://src/data/encounter_registry.gd")


func test_enemy_registry_contains_initial_families() -> void:
	var ids := EnemyRegistryScript.get_all_archetype_ids()

	assert_eq(ids.size(), 7)
	assert_true(EnemyRegistryScript.BANDIT_THUG_ID in ids)
	assert_true(EnemyRegistryScript.BANDIT_RAIDER_ID in ids)
	assert_true(EnemyRegistryScript.BANDIT_MARKSMAN_ID in ids)
	assert_true(EnemyRegistryScript.UNDEAD_ZOMBIE_ID in ids)
	assert_true(EnemyRegistryScript.UNDEAD_SKELETON_ID in ids)
	assert_true(EnemyRegistryScript.BEAST_WOLF_ID in ids)
	assert_true(EnemyRegistryScript.BEAST_SPIDER_ID in ids)


func test_enemy_archetype_creates_ai_combat_unit() -> void:
	var unit := EnemyRegistryScript.create_unit(
		EnemyRegistryScript.BANDIT_MARKSMAN_ID, "enemy_1", Vector2i(3, 4)
	)

	assert_eq(unit.id, "enemy_1")
	assert_eq(unit.team, "enemy")
	assert_true(unit.is_ai)
	assert_eq(unit.position, Vector2i(3, 4))
	assert_gt(unit.ranged_skill, unit.melee_skill)
	assert_gt(unit.ammo, 0)


func test_encounter_registry_creates_basic_encounters() -> void:
	var encounter_ids := EncounterRegistryScript.get_all_encounter_ids()

	assert_eq(encounter_ids.size(), 3)
	assert_true(EncounterRegistryScript.BANDIT_SKIRMISH_ID in encounter_ids)
	assert_true(EncounterRegistryScript.UNDEAD_SKIRMISH_ID in encounter_ids)
	assert_true(EncounterRegistryScript.BEAST_SKIRMISH_ID in encounter_ids)


func test_bandit_encounter_has_three_enemy_roles() -> void:
	var encounter = EncounterRegistryScript.get_encounter(EncounterRegistryScript.BANDIT_SKIRMISH_ID)
	var units: Array[CombatUnit] = encounter.create_enemy_units()

	assert_eq(units.size(), 3)
	assert_eq(units[0].team, "enemy")
	assert_true(units[0].is_ai)
	assert_true(units[1].is_ai)
	assert_true(units[2].is_ai)
	assert_gt(units[2].ranged_skill, 0)


func test_undead_and_beast_encounters_have_two_units_each() -> void:
	var undead = EncounterRegistryScript.get_encounter(EncounterRegistryScript.UNDEAD_SKIRMISH_ID)
	var beast = EncounterRegistryScript.get_encounter(EncounterRegistryScript.BEAST_SKIRMISH_ID)

	assert_eq(undead.create_enemy_units().size(), 2)
	assert_eq(beast.create_enemy_units().size(), 2)
