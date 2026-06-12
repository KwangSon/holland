extends GutTest


func _make_unit(overrides: Dictionary = {}) -> CombatUnit:
	var defaults := {
		"id": "u1",
		"display_name": "Test",
		"team": "player",
		"position": Vector2i(0, 0),
		"max_hp": 40,
		"hp": 40,
		"max_action_points": 9,
		"max_fatigue": 100,
		"initiative": 20,
		"melee_skill": 95,
		"ranged_skill": 60,
		"melee_defense": 20,
		"ranged_defense": 20,
		"resolve": 50,
		"damage": 12,
		"chance_to_hit_head": 0,
	}
	defaults.merge(overrides, true)
	return CombatUnit.create(defaults)


func test_body_large_hp_damage_applies_deep_wound_penalty() -> void:
	var attacker := _make_unit({"id": "a", "team": "player", "initiative": 40})
	var defender := _make_unit({"id": "d", "team": "enemy", "position": Vector2i(1, 0)})
	var state := CombatState.new()
	state.start_encounter([attacker], [defender], [Vector2i(0, 0), Vector2i(1, 0)], 42)

	var result := state.attack("a", "d")
	var injury: Dictionary = result.get("injury", {})

	assert_eq(injury.get("injury_id", ""), InjuryRegistry.DEEP_WOUND_ID)
	assert_true(defender.has_injury(InjuryRegistry.DEEP_WOUND_ID))
	assert_eq(defender.melee_defense, 15)
	assert_eq(defender.ranged_defense, 15)


func test_head_large_hp_damage_applies_concussion_penalty() -> void:
	var attacker := _make_unit(
		{"id": "a", "team": "player", "initiative": 40, "chance_to_hit_head": 100}
	)
	var defender := _make_unit({"id": "d", "team": "enemy", "position": Vector2i(1, 0)})
	var state := CombatState.new()
	state.start_encounter([attacker], [defender], [Vector2i(0, 0), Vector2i(1, 0)], 42)

	var result := state.attack("a", "d")
	var injury: Dictionary = result.get("injury", {})

	assert_eq(injury.get("injury_id", ""), InjuryRegistry.CONCUSSION_ID)
	assert_true(defender.has_injury(InjuryRegistry.CONCUSSION_ID))
	assert_eq(defender.melee_skill, 85)
	assert_eq(defender.ranged_skill, 50)


func test_duplicate_injury_is_not_added_twice() -> void:
	var unit := _make_unit({"id": "u"})

	assert_true(unit.apply_injury(InjuryRegistry.DEEP_WOUND_ID))
	assert_false(unit.apply_injury(InjuryRegistry.DEEP_WOUND_ID))
	assert_eq(unit.get_injury_ids().size(), 1)
	assert_eq(unit.melee_defense, 15)


func test_small_hp_damage_does_not_apply_injury() -> void:
	var defender := _make_unit({"id": "d", "team": "enemy"})

	assert_false(CombatRules.should_apply_temporary_injury(defender, 11))
	assert_true(CombatRules.should_apply_temporary_injury(defender, 12))
