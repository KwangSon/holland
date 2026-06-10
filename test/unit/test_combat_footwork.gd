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


func _start_state(player_units: Array[CombatUnit], enemy_units: Array[CombatUnit]) -> CombatState:
	var state := CombatState.new()
	state.start_encounter(
		player_units,
		enemy_units,
		[
			Vector2i(0, 0),
			Vector2i(1, 0),
			Vector2i(2, 0),
			Vector2i(3, 0),
			Vector2i(4, 0),
		],
		42
	)
	return state


func test_footwork_cost_reduces_legal_move_budget() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 40})
	var state := _start_state([player], [])

	assert_true(Vector2i(4, 0) in state.get_legal_moves("p"))
	assert_false(Vector2i(4, 0) in state.get_legal_moves("p", CombatSkillRegistry.FOOTWORK_ID))


func test_footwork_ignores_zoc_escape_attacks_and_consumes_skill_cost() -> void:
	var player := _make_unit(
		{"id": "p", "team": "player", "position": Vector2i(1, 0), "initiative": 40}
	)
	var enemy := _make_unit(
		{"id": "e", "team": "enemy", "position": Vector2i(2, 0), "melee_skill": 95}
	)
	var state := _start_state([player], [enemy])

	assert_true(state.move_unit("p", Vector2i(0, 0), CombatSkillRegistry.FOOTWORK_ID))
	assert_eq(player.position, Vector2i(0, 0))
	assert_eq(player.action_points, 4)
	assert_eq(player.fatigue, 29)
	assert_true(state.get_last_move_result()["ignored_zoc"])
	assert_eq(state.get_last_move_result()["zoc_attacks"].size(), 0)
