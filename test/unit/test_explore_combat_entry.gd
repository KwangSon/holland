extends GutTest

const EncounterRegistryScript := preload("res://src/data/encounter_registry.gd")


func test_explore_zones_map_to_registered_encounters() -> void:
	var screen := autofree(ExploreScreen.new()) as ExploreScreen
	var zones: Array[Dictionary] = screen._get_village_zones()

	assert_eq(zones.size(), 3)
	assert_eq(zones[0].get("name"), "성채")
	assert_eq(zones[0].get("encounter_id"), EncounterRegistryScript.BANDIT_SKIRMISH_ID)
	assert_eq(zones[1].get("name"), "폐허")
	assert_eq(zones[1].get("encounter_id"), EncounterRegistryScript.UNDEAD_SKIRMISH_ID)
	assert_eq(zones[2].get("name"), "거미 숲")
	assert_eq(zones[2].get("encounter_id"), EncounterRegistryScript.BEAST_SKIRMISH_ID)


func test_explore_zone_encounter_payload_can_restore_combat_enemies() -> void:
	var explore_screen := autofree(ExploreScreen.new()) as ExploreScreen
	var combat_screen := autofree(CombatScreen.new()) as CombatScreen

	for zone: Dictionary in explore_screen._get_village_zones():
		var encounter = EncounterRegistryScript.get_encounter(zone["encounter_id"])
		var payload: Dictionary = encounter.to_rna()
		var enemy_units: Array[CombatUnit] = combat_screen._enemy_units_from_encounter(payload)

		assert_gt(enemy_units.size(), 0)
		assert_eq(payload.get("encounter_id"), zone.get("encounter_id"))
		for unit: CombatUnit in enemy_units:
			assert_eq(unit.team, "enemy")
			assert_true(unit.is_ai)
