extends GutTest

const CombatSkillRegistryScript := preload("res://src/combat/combat_skill_registry.gd")


func test_registry_contains_initial_combat_skills() -> void:
	var skill_ids := CombatSkillRegistryScript.get_all_skill_ids()
	for expected_id: String in [
		"basic_attack",
		"spear_thrust",
		"mace_strike",
		"ranged_shot",
		"shieldwall",
		"wait",
		"recover",
		"footwork",
	]:
		assert_true(expected_id in skill_ids, "missing skill %s" % expected_id)


func test_registry_returns_fresh_skill_instances() -> void:
	var first = CombatSkillRegistryScript.get_skill("basic_attack")
	var second = CombatSkillRegistryScript.get_skill("basic_attack")
	first.hit_modifier = 99
	assert_eq(second.hit_modifier, 0)


func test_attack_skill_ids_include_initial_weapon_attacks() -> void:
	assert_eq(
		CombatSkillRegistryScript.get_attack_skill_ids(),
		["basic_attack", "spear_thrust", "mace_strike", "ranged_shot"]
	)


func test_weapon_family_skills_have_distinct_combat_profiles() -> void:
	var spear = CombatSkillRegistryScript.get_skill("spear_thrust")
	var mace = CombatSkillRegistryScript.get_skill("mace_strike")
	var ranged = CombatSkillRegistryScript.get_skill("ranged_shot")
	assert_true("spear" in spear.tags)
	assert_eq(spear.hit_modifier, 10)
	assert_true("mace" in mace.tags)
	assert_eq(mace.armor_damage_percent, 120)
	assert_true("ranged" in ranged.tags)
	assert_eq(ranged.attack_range, 6)
	assert_eq(ranged.distance_penalty_per_tile, 5)


func test_utility_skills_define_costs_and_tags() -> void:
	var shieldwall = CombatSkillRegistryScript.get_skill("shieldwall")
	var wait = CombatSkillRegistryScript.get_skill("wait")
	var recover = CombatSkillRegistryScript.get_skill("recover")
	var footwork = CombatSkillRegistryScript.get_skill("footwork")
	assert_true("shield" in shieldwall.tags)
	assert_eq(wait.action_point_cost, 0)
	assert_eq(recover.action_point_cost, 9)
	assert_eq(recover.fatigue_recovery, 30)
	assert_true("zoc_ignore" in footwork.tags)
