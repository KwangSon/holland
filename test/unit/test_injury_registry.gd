extends GutTest


func test_registry_returns_core_temporary_injuries() -> void:
	var concussion = InjuryRegistry.get_injury(InjuryRegistry.CONCUSSION_ID)
	var deep_wound = InjuryRegistry.get_injury(InjuryRegistry.DEEP_WOUND_ID)

	assert_eq(concussion.display_name, "뇌진탕")
	assert_eq(concussion.body_part, "head")
	assert_eq(concussion.stat_modifiers.get("melee_skill", 0), -10)
	assert_eq(deep_wound.display_name, "깊은 상처")
	assert_eq(deep_wound.body_part, "body")
	assert_eq(deep_wound.stat_modifiers.get("melee_defense", 0), -5)


func test_registry_sums_injury_modifiers() -> void:
	var injury_ids: Array[String] = [
		InjuryRegistry.CONCUSSION_ID,
		InjuryRegistry.DEEP_WOUND_ID,
	]

	assert_eq(InjuryRegistry.get_melee_skill_modifier(injury_ids), -10)
	assert_eq(InjuryRegistry.get_ranged_skill_modifier(injury_ids), -10)
	assert_eq(InjuryRegistry.get_melee_defense_modifier(injury_ids), -5)
	assert_eq(InjuryRegistry.get_ranged_defense_modifier(injury_ids), -5)
