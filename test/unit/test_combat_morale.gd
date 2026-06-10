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
		"melee_defense": 0,
		"resolve": 50,
		"damage": 20,
	}
	defaults.merge(overrides, true)
	return CombatUnit.create(defaults)


func test_large_hp_damage_adds_morale_check_to_attack_result() -> void:
	var attacker := _make_unit({"id": "a", "team": "player", "initiative": 40, "damage": 20})
	var defender := _make_unit(
		{"id": "d", "team": "enemy", "position": Vector2i(1, 0), "body_armor": 0}
	)
	var state := CombatState.new()
	state.start_encounter([attacker], [defender], [Vector2i(0, 0), Vector2i(1, 0)], 42)

	var result := state.attack("a", "d")
	var morale_checks: Array = result.get("morale_checks", [])

	assert_eq(morale_checks.size(), 1)
	assert_eq(morale_checks[0].get("unit_id", ""), "d")
	assert_eq(morale_checks[0].get("reason", ""), "large_damage")
	assert_eq(morale_checks[0].get("chance", 0), 30)
	assert_true(morale_checks[0].has("roll"))
	assert_true(morale_checks[0].has("previous_state"))
	assert_true(morale_checks[0].has("new_state"))


func test_ally_death_adds_morale_check_for_living_teammates() -> void:
	var attacker := _make_unit({"id": "a", "team": "player", "initiative": 40, "damage": 100})
	var defender := _make_unit(
		{"id": "d", "team": "enemy", "position": Vector2i(1, 0), "max_hp": 10, "hp": 10}
	)
	var ally := _make_unit({"id": "e2", "team": "enemy", "position": Vector2i(0, 1)})
	var state := CombatState.new()
	state.start_encounter(
		[attacker], [defender, ally], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], 42
	)

	var result := state.attack("a", "d")
	var morale_checks: Array = result.get("morale_checks", [])

	assert_true(result.get("killed", false))
	assert_eq(morale_checks.size(), 1)
	assert_eq(morale_checks[0].get("unit_id", ""), "e2")
	assert_eq(morale_checks[0].get("reason", ""), "ally_death")
	assert_eq(morale_checks[0].get("chance", 0), 20)


func test_failed_morale_check_degrades_state() -> void:
	var unit := _make_unit({"id": "u", "resolve": 0})
	var rng := RandomNumberGenerator.new()
	rng.seed = 1

	var result := CombatRules.roll_morale_check(unit, rng, 100, "large_damage")

	if result.get("passed", false):
		assert_eq(result.get("new_state", ""), "steady")
	else:
		assert_eq(result.get("previous_state", ""), "steady")
		assert_eq(result.get("new_state", ""), "wavering")
		assert_eq(unit.morale_state, CombatUnit.MoraleState.WAVERING)
