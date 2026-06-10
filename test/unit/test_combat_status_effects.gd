extends GutTest

const StatusRegistry := preload("res://src/combat/combat_status_effect_registry.gd")


func _make_unit(overrides: Dictionary = {}) -> CombatUnit:
	var defaults := {
		"id": "u1",
		"display_name": "Test",
		"team": "player",
		"position": Vector2i(0, 0),
		"max_hp": 30,
		"max_action_points": 9,
		"max_fatigue": 100,
		"initiative": 20,
		"melee_skill": 60,
		"melee_defense": 20,
		"ranged_defense": 20,
		"damage": 10,
	}
	defaults.merge(overrides, true)
	return CombatUnit.create(defaults)


func _start_state(player: CombatUnit, enemy: CombatUnit) -> CombatState:
	var state := CombatState.new()
	state.start_encounter(
		[player], [enemy], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], 42
	)
	return state


func test_status_registry_contains_minimum_statuses() -> void:
	var status_ids: Array[String] = StatusRegistry.get_all_status_ids()

	assert_true(StatusRegistry.STUNNED_ID in status_ids)
	assert_true(StatusRegistry.BLEEDING_ID in status_ids)
	assert_true(StatusRegistry.NETTED_ID in status_ids)
	assert_true(StatusRegistry.SHIELDWALL_ID in status_ids)


func test_netted_blocks_movement_until_turn_ends() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 40})
	var enemy := _make_unit({"id": "e", "team": "enemy", "position": Vector2i(1, 0)})
	var state := _start_state(player, enemy)

	assert_true(state.apply_status("p", StatusRegistry.NETTED_ID, 1))
	assert_eq(state.get_legal_moves("p"), [])

	state.end_turn()
	state.end_turn()

	assert_false(player.has_status(StatusRegistry.NETTED_ID))
	assert_false(state.get_legal_moves("p").is_empty())


func test_stunned_blocks_attack_and_recover() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 40, "fatigue": 30})
	var enemy := _make_unit({"id": "e", "team": "enemy", "position": Vector2i(1, 0)})
	var state := _start_state(player, enemy)

	assert_true(state.apply_status("p", StatusRegistry.STUNNED_ID, 1))

	assert_eq(state.get_attack_targets("p"), [])
	assert_true(state.attack("p", "e").is_empty())
	assert_false(state.recover("p"))


func test_shieldwall_status_increases_defense_for_hit_chance() -> void:
	var attacker := _make_unit({"id": "a", "melee_skill": 60})
	var defender := _make_unit({"id": "d", "team": "enemy", "position": Vector2i(1, 0)})

	assert_eq(CombatRules.calculate_hit_chance(attacker, defender), 40)

	defender.apply_status(StatusRegistry.SHIELDWALL_ID, 1)

	assert_eq(CombatRules.calculate_hit_chance(attacker, defender), 25)


func test_shieldwall_skill_applies_status_and_consumes_costs() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 40})
	var enemy := _make_unit({"id": "e", "team": "enemy", "position": Vector2i(1, 0)})
	var state := _start_state(player, enemy)

	var result := state.use_skill("p", CombatSkillRegistry.SHIELDWALL_ID)

	assert_eq(result.get("status_effect_id", ""), StatusRegistry.SHIELDWALL_ID)
	assert_true(player.has_status(StatusRegistry.SHIELDWALL_ID))
	assert_eq(player.status_turns[StatusRegistry.SHIELDWALL_ID], 2)
	assert_eq(player.action_points, 5)
	assert_eq(player.fatigue, 20)
	assert_eq(CombatRules.calculate_hit_chance(enemy, player), 25)

	state.end_turn()

	assert_true(player.has_status(StatusRegistry.SHIELDWALL_ID))

	state.end_turn()

	assert_true(player.has_status(StatusRegistry.SHIELDWALL_ID))

	state.end_turn()

	assert_true(player.has_status(StatusRegistry.SHIELDWALL_ID))

	state.end_turn()

	assert_false(player.has_status(StatusRegistry.SHIELDWALL_ID))


func test_bleeding_deals_damage_at_start_of_affected_turn() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 40})
	var enemy := _make_unit(
		{"id": "e", "team": "enemy", "position": Vector2i(1, 0), "initiative": 10}
	)
	var state := _start_state(player, enemy)

	assert_true(state.apply_status("e", StatusRegistry.BLEEDING_ID, 2))
	state.end_turn()

	assert_eq(enemy.hp, 27)

	state.end_turn()
	state.end_turn()

	assert_eq(enemy.hp, 24)
	state.end_turn()
	assert_false(enemy.has_status(StatusRegistry.BLEEDING_ID))
