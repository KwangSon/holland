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


func test_attack_consumes_ap_and_fatigue() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 40})
	var enemy := _make_unit({"id": "e", "team": "enemy", "position": Vector2i(1, 0)})
	var state := _start_state([player], [enemy], [Vector2i(0, 0), Vector2i(1, 0)])

	var result := state.attack("p", "e")
	assert_true(result.has("hit"))
	assert_eq(player.action_points, 5)
	assert_eq(player.fatigue, 30)


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
