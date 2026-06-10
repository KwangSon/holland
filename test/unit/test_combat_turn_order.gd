extends GutTest


func _make_unit(overrides: Dictionary = {}) -> CombatUnit:
	var defaults := {
		"id": "u1",
		"display_name": "Test",
		"team": "player",
		"position": Vector2i(0, 0),
		"max_hp": 100,
		"max_action_points": 9,
		"max_fatigue": 100,
		"initiative": 20,
		"melee_skill": 95,
		"damage": 1,
	}
	defaults.merge(overrides, true)
	return CombatUnit.create(defaults)


func test_next_round_turn_order_uses_fatigue_before_recovery() -> void:
	var player := _make_unit({"id": "p", "team": "player", "initiative": 50})
	var enemy := _make_unit(
		{"id": "e", "team": "enemy", "position": Vector2i(1, 0), "initiative": 20}
	)
	var state := CombatState.new()
	state.start_encounter([player], [enemy], [Vector2i(0, 0), Vector2i(1, 0)], 42)

	assert_eq(state.get_active_unit().id, "p")
	assert_true(state.attack("p", "e").has("hit"))
	assert_true(state.attack("p", "e").has("hit"))

	state.end_turn()
	assert_eq(state.get_active_unit().id, "e")

	state.end_turn()
	assert_eq(state.round_number, 2)
	assert_eq(state.get_active_unit().id, "e")
