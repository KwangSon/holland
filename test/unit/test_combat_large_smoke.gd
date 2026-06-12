extends GutTest

const CombatAiScript := preload("res://src/combat/combat_ai.gd")

const UNIT_COUNT_PER_SIDE := 20
const SMOKE_TURN_COUNT := 80


func test_twenty_vs_twenty_ai_turns_do_not_stall() -> void:
	var state := CombatState.new()
	state.start_encounter(
		_create_units("p", "player", 1),
		_create_units("e", "enemy", 16),
		_create_cells(),
		77
	)

	for _i: int in SMOKE_TURN_COUNT:
		var active := state.get_active_unit()
		assert_not_null(active)
		assert_eq(state.get_outcome(), "ongoing")

		var action: Dictionary = CombatAiScript.select_action(active, state)
		_apply_ai_action(state, active, action)
		state.end_turn()

	assert_gt(state.round_number, 1)


func _apply_ai_action(state: CombatState, active: CombatUnit, action: Dictionary) -> void:
	if action.is_empty():
		return
	var move_cell: Vector2i = action.get("move_cell", active.position)
	if move_cell != active.position:
		state.move_unit(active.id, move_cell)
	var target_id: String = action.get("attack_target_id", "")
	if target_id.is_empty():
		return
	var skill_id: String = action.get("attack_skill_id", CombatSkillRegistry.BASIC_ATTACK_ID)
	state.attack(active.id, target_id, skill_id)


func _create_units(id_prefix: String, team: String, start_x: int) -> Array[CombatUnit]:
	var units: Array[CombatUnit] = []
	for i: int in UNIT_COUNT_PER_SIDE:
		units.append(
			CombatUnit.create(
				{
					"id": "%s%d" % [id_prefix, i],
					"display_name": "%s %d" % [team, i],
					"team": team,
					"position": Vector2i(start_x + i % 2, 1 + floori(i / 2.0)),
					"max_hp": 30,
					"max_fatigue": 100,
					"initiative": 40 - i,
					"melee_skill": 55,
					"melee_defense": 5,
					"damage": 10,
					"skill_ids": [CombatSkillRegistry.BASIC_ATTACK_ID],
					"is_ai": true,
				}
			)
		)
	return units


func _create_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x: int in range(0, 18):
		for y: int in range(0, 14):
			cells.append(Vector2i(x, y))
	return cells
