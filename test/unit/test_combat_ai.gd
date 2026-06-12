extends GutTest

const CombatAiScript := preload("res://src/combat/combat_ai.gd")


func _make_unit(overrides: Dictionary = {}) -> CombatUnit:
	var defaults := {
		"id": "u1",
		"display_name": "Test",
		"team": "player",
		"position": Vector2i(0, 0),
		"max_hp": 30,
		"max_action_points": 9,
		"max_fatigue": 100,
		"initiative": 50,
		"melee_skill": 60,
		"ranged_skill": 60,
		"melee_defense": 0,
		"ranged_defense": 0,
		"damage": 10,
		"ammo": 4,
		"max_ammo": 4,
	}
	defaults.merge(overrides, true)
	return CombatUnit.create(defaults)


func _start_state(
	player_units: Array[CombatUnit], enemy_units: Array[CombatUnit], cells: Array[Vector2i]
) -> CombatState:
	var state := CombatState.new()
	state.start_encounter(player_units, enemy_units, cells, 42)
	return state


func test_ai_uses_available_ranged_skill_without_moving() -> void:
	var player := _make_unit({"id": "p", "team": "player", "position": Vector2i(3, 0)})
	var archer := _make_unit(
		{
			"id": "e",
			"team": "enemy",
			"position": Vector2i(0, 0),
			"skill_ids": [CombatSkillRegistry.RANGED_SHOT_ID],
			"initiative": 80,
		}
	)
	var state := _start_state(
		[player], [archer], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	)

	var action: Dictionary = CombatAiScript.select_action(archer, state)

	assert_eq(action.get("move_cell"), Vector2i(0, 0))
	assert_eq(action.get("attack_target_id"), "p")
	assert_eq(action.get("attack_skill_id"), CombatSkillRegistry.RANGED_SHOT_ID)


func test_ai_moves_to_attack_after_movement() -> void:
	var player := _make_unit({"id": "p", "team": "player", "position": Vector2i(2, 0)})
	var enemy := _make_unit(
		{
			"id": "e",
			"team": "enemy",
			"position": Vector2i(0, 0),
			"skill_ids": [CombatSkillRegistry.BASIC_ATTACK_ID],
			"initiative": 80,
		}
	)
	var state := _start_state(
		[player], [enemy], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	)

	var action: Dictionary = CombatAiScript.select_action(enemy, state)

	assert_eq(action.get("move_cell"), Vector2i(1, 0))
	assert_eq(action.get("attack_target_id"), "p")
	assert_eq(action.get("attack_skill_id"), CombatSkillRegistry.BASIC_ATTACK_ID)


func test_ai_avoids_zoc_escape_when_no_attack_is_available() -> void:
	var controller := _make_unit({"id": "c", "team": "player", "position": Vector2i(0, 1)})
	var enemy := _make_unit(
		{
			"id": "e",
			"team": "enemy",
			"position": Vector2i(0, 0),
			"skill_ids": [CombatSkillRegistry.BASIC_ATTACK_ID],
			"initiative": 80,
			"morale_state": CombatUnit.MoraleState.STEADY,
		}
	)
	enemy.apply_status(CombatStatusEffectRegistry.STUNNED_ID, 1)
	var state := _start_state(
		[controller],
		[enemy],
		[
			Vector2i(0, 0),
			Vector2i(0, 1),
			Vector2i(1, 0),
			Vector2i(1, 1),
		]
	)

	var action: Dictionary = CombatAiScript.select_action(enemy, state)

	assert_eq(action.get("move_cell"), Vector2i(0, 0))
	assert_eq(action.get("attack_target_id"), "")


func test_fleeing_ai_moves_toward_board_edge_without_attacking() -> void:
	var player := _make_unit({"id": "p", "team": "player", "position": Vector2i(4, 2)})
	var enemy := _make_unit(
		{
			"id": "e",
			"team": "enemy",
			"position": Vector2i(2, 2),
			"initiative": 80,
			"morale_state": CombatUnit.MoraleState.FLEEING,
		}
	)
	var cells: Array[Vector2i] = []
	for x: int in range(5):
		for y: int in range(5):
			cells.append(Vector2i(x, y))
	var state := _start_state([player], [enemy], cells)

	var action: Dictionary = CombatAiScript.select_action(enemy, state)
	var move_cell: Vector2i = action.get("move_cell", enemy.position)

	assert_true(enemy.is_fleeing())
	assert_eq(action.get("attack_target_id"), "")
	assert_eq(action.get("attack_skill_id"), "")
	assert_true(move_cell.x == 0 or move_cell.x == 4 or move_cell.y == 0 or move_cell.y == 4)
