extends GutTest


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
		"melee_skill": 95,
		"damage": 10,
	}
	defaults.merge(overrides, true)
	return CombatUnit.create(defaults)


func _start_state(
	player_units: Array[CombatUnit], enemy_units: Array[CombatUnit], cells: Array[Vector2i]
) -> CombatState:
	var state := CombatState.new()
	state.start_encounter(player_units, enemy_units, cells, 42)
	return state


func test_start_encounter_uses_current_initiative_order() -> void:
	var slow_player := _make_unit({"id": "p", "team": "player", "initiative": 10})
	var fast_enemy := _make_unit(
		{"id": "e", "team": "enemy", "position": Vector2i(1, 0), "initiative": 40}
	)
	var state := _start_state([slow_player], [fast_enemy], [Vector2i(0, 0), Vector2i(1, 0)])
	assert_eq(state.get_active_unit().id, "e")


func test_start_encounter_tiles_preserves_terrain_and_height() -> void:
	var player := _make_unit({"id": "p", "team": "player"})
	var enemy := _make_unit({"id": "e", "team": "enemy", "position": Vector2i(1, 0)})
	var state := CombatState.new()
	(
		state
		. start_encounter_tiles(
			[player],
			[enemy],
			{
				Vector2i(0, 0): {"terrain": CombatTileData.TerrainType.PLAIN, "height": 0},
				Vector2i(1, 0): {"terrain": CombatTileData.TerrainType.ROUGH, "height": 2},
			},
			42
		)
	)
	assert_eq(state.get_board().get_terrain(Vector2i(1, 0)), CombatTileData.TerrainType.ROUGH)
	assert_eq(state.get_board().get_height(Vector2i(1, 0)), 2)


func test_fatigue_reduces_current_initiative_order() -> void:
	var tired_fast_unit := _make_unit(
		{"id": "p", "team": "player", "initiative": 50, "fatigue": 45}
	)
	var steady_unit := _make_unit(
		{"id": "e", "team": "enemy", "position": Vector2i(1, 0), "initiative": 20}
	)
	var state := _start_state([tired_fast_unit], [steady_unit], [Vector2i(0, 0), Vector2i(1, 0)])
	assert_eq(state.get_active_unit().id, "e")


func test_move_unit_consumes_path_ap_and_fatigue_without_ending_turn() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 40})
	var enemy := _make_unit({"id": "e", "team": "enemy", "position": Vector2i(2, 0)})
	var state := _start_state([player], [enemy], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])

	assert_true(state.move_unit("p", Vector2i(1, 0)))
	assert_eq(player.position, Vector2i(1, 0))
	assert_eq(player.action_points, 7)
	assert_eq(player.fatigue, 4)
	assert_eq(state.get_active_unit().id, "p")


func test_non_active_unit_cannot_move_or_attack() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 40})
	var enemy := _make_unit(
		{"id": "e", "team": "enemy", "position": Vector2i(1, 0), "initiative": 10}
	)
	var state := _start_state([player], [enemy], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])

	assert_false(state.move_unit("e", Vector2i(2, 0)))
	assert_true(state.attack("e", "p").is_empty())
	assert_eq(state.get_legal_moves("e").size(), 0)
	assert_eq(state.get_attack_targets("e").size(), 0)


func test_unit_can_move_then_attack_in_same_turn() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 40})
	var enemy := _make_unit({"id": "e", "team": "enemy", "position": Vector2i(2, 0)})
	var state := _start_state([player], [enemy], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])

	assert_true(state.move_unit("p", Vector2i(1, 0)))
	var result := state.attack("p", "e")

	assert_true(result.has("hit"))
	assert_eq(player.action_points, 3)
	assert_eq(player.fatigue, 34)


func test_attack_consumes_ap_and_fatigue() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 40})
	var enemy := _make_unit({"id": "e", "team": "enemy", "position": Vector2i(1, 0)})
	var state := _start_state([player], [enemy], [Vector2i(0, 0), Vector2i(1, 0)])

	var result := state.attack("p", "e")
	assert_true(result.has("hit"))
	assert_eq(player.action_points, 5)
	assert_eq(player.fatigue, 30)


func test_attack_with_skill_id_uses_skill_range_and_costs() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 40})
	var enemy := _make_unit({"id": "e", "team": "enemy", "position": Vector2i(2, 0)})
	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var state := _start_state([player], [enemy], cells)

	assert_eq(state.get_attack_targets("p").size(), 0)
	assert_eq(state.get_attack_targets("p", CombatSkillRegistry.RANGED_SHOT_ID), ["e"])

	var result := state.attack("p", "e", CombatSkillRegistry.RANGED_SHOT_ID)
	assert_eq(result.get("skill_id", ""), CombatSkillRegistry.RANGED_SHOT_ID)
	assert_eq(player.action_points, 5)
	assert_eq(player.fatigue, 20)


func test_unit_can_attack_multiple_times_while_ap_and_fatigue_allow() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 40})
	var enemy := _make_unit({"id": "e", "team": "enemy", "position": Vector2i(1, 0), "max_hp": 40})
	var state := _start_state([player], [enemy], [Vector2i(0, 0), Vector2i(1, 0)])

	assert_true(state.attack("p", "e").has("hit"))
	assert_true(state.attack("p", "e").has("hit"))

	assert_eq(player.action_points, 1)
	assert_eq(player.fatigue, 60)


func test_attack_requires_enough_ap() -> void:
	var player := _make_unit(
		{"id": "p", "team": "player", "initiative": 40, "max_action_points": 3}
	)
	var enemy := _make_unit({"id": "e", "team": "enemy", "position": Vector2i(1, 0)})
	var state := _start_state([player], [enemy], [Vector2i(0, 0), Vector2i(1, 0)])

	assert_eq(state.get_attack_targets("p").size(), 0)
	assert_true(state.attack("p", "e").is_empty())


func test_attack_requires_fatigue_capacity() -> void:
	var player := _make_unit(
		{"id": "p", "team": "player", "initiative": 40, "fatigue": 80, "max_fatigue": 100}
	)
	var enemy := _make_unit({"id": "e", "team": "enemy", "position": Vector2i(1, 0)})
	var state := _start_state([player], [enemy], [Vector2i(0, 0), Vector2i(1, 0)])

	assert_eq(state.get_attack_targets("p").size(), 0)
	assert_true(state.attack("p", "e").is_empty())
	assert_eq(player.action_points, 9)
	assert_eq(player.fatigue, 80)


func test_lethal_attack_clears_occupancy_and_removes_dead_unit_from_queue() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 40, "damage": 100})
	var enemy := _make_unit(
		{
			"id": "e",
			"team": "enemy",
			"position": Vector2i(1, 0),
			"initiative": 10,
			"max_hp": 5,
			"hp": 5,
		}
	)
	var state := _start_state([player], [enemy], [Vector2i(0, 0), Vector2i(1, 0)])

	var result := state.attack("p", "e")

	assert_true(result.get("killed", false))
	assert_false(state.get_board().occupied.has(Vector2i(1, 0)))
	var remaining_ids := state.get_remaining_turn_queue().map(
		func(unit: CombatUnit) -> String: return unit.id
	)
	assert_eq(remaining_ids, ["p"])
	assert_eq(state.get_outcome(), "victory")


func test_recover_consumes_ap_and_reduces_fatigue() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 80, "fatigue": 50})
	var enemy := _make_unit({"id": "e", "team": "enemy", "position": Vector2i(1, 0)})
	var state := _start_state([player], [enemy], [Vector2i(0, 0), Vector2i(1, 0)])

	assert_true(state.recover("p"))
	assert_eq(player.action_points, 0)
	assert_eq(player.fatigue, 20)


func test_recover_requires_active_unit_and_enough_ap() -> void:
	var player := _make_unit(
		{"id": "p", "team": "player", "initiative": 40, "max_action_points": 8}
	)
	var enemy := _make_unit({"id": "e", "team": "enemy", "position": Vector2i(1, 0)})
	var state := _start_state([player], [enemy], [Vector2i(0, 0), Vector2i(1, 0)])

	assert_false(state.recover("p"))
	assert_false(state.recover("e"))
	assert_eq(player.fatigue, 0)


func test_end_turn_starts_next_unit_with_ap_reset_and_fatigue_recovery() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 40})
	var enemy := _make_unit(
		{
			"id": "e",
			"team": "enemy",
			"position": Vector2i(1, 0),
			"initiative": 10,
			"action_points": 1,
			"fatigue": 20,
		}
	)
	var state := _start_state([player], [enemy], [Vector2i(0, 0), Vector2i(1, 0)])

	state.end_turn()

	assert_eq(state.get_active_unit().id, "e")
	assert_eq(enemy.action_points, 9)
	assert_eq(enemy.fatigue, 5)


func test_wait_turn_defers_unit_to_end_of_current_round_without_reset() -> void:
	var first := _make_unit({"id": "p1", "team": "player", "initiative": 50, "action_points": 3})
	var second := _make_unit(
		{"id": "p2", "team": "player", "position": Vector2i(1, 0), "initiative": 40}
	)
	var enemy := _make_unit(
		{"id": "e", "team": "enemy", "position": Vector2i(2, 0), "initiative": 10}
	)
	var state := _start_state(
		[first, second], [enemy], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	)
	first.action_points = 3

	state.wait_turn()
	assert_eq(state.get_active_unit().id, "p2")

	state.end_turn()
	assert_eq(state.get_active_unit().id, "e")

	state.end_turn()
	assert_eq(state.get_active_unit().id, "p1")
	assert_eq(first.action_points, 3)


func test_remaining_turn_queue_includes_all_teams_in_order() -> void:
	var first := _make_unit({"id": "p1", "team": "player", "initiative": 50})
	var enemy := _make_unit(
		{"id": "e", "team": "enemy", "position": Vector2i(1, 0), "initiative": 40}
	)
	var second := _make_unit(
		{"id": "p2", "team": "player", "position": Vector2i(2, 0), "initiative": 30}
	)
	var state := _start_state(
		[first, second], [enemy], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	)

	var queue := state.get_remaining_turn_queue()

	assert_eq(queue.map(func(unit: CombatUnit) -> String: return unit.id), ["p1", "e", "p2"])


func test_unit_can_move_into_hostile_zoc() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 40})
	var enemy := _make_unit(
		{"id": "e", "team": "enemy", "position": Vector2i(2, 0), "initiative": 10}
	)
	var state := _start_state([player], [enemy], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])

	assert_true(state.move_unit("p", Vector2i(1, 0)))


func test_zoc_escape_attack_hit_blocks_movement() -> void:
	var player := _make_unit(
		{"id": "p", "team": "player", "position": Vector2i(1, 0), "initiative": 40}
	)
	var enemy := _make_unit(
		{
			"id": "e",
			"team": "enemy",
			"position": Vector2i(2, 0),
			"initiative": 10,
			"melee_skill": 95,
		}
	)
	var state := _start_state([player], [enemy], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])

	assert_false(state.move_unit("p", Vector2i(0, 0)))
	assert_eq(player.position, Vector2i(1, 0))
	assert_true(state.get_last_move_result()["blocked_by_zoc"])
	assert_eq(state.get_last_move_result()["zoc_attacks"].size(), 1)


func test_zoc_escape_attack_miss_allows_movement() -> void:
	var player := _make_unit(
		{"id": "p", "team": "player", "position": Vector2i(1, 0), "initiative": 40}
	)
	var enemy := _make_unit(
		{
			"id": "e",
			"team": "enemy",
			"position": Vector2i(2, 0),
			"initiative": 10,
			"melee_skill": 0,
		}
	)
	var state := _start_state([player], [enemy], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])

	assert_true(state.move_unit("p", Vector2i(0, 0)))
	assert_eq(player.position, Vector2i(0, 0))
	assert_false(state.get_last_move_result()["blocked_by_zoc"])
	assert_eq(state.get_last_move_result()["zoc_attacks"].size(), 1)
