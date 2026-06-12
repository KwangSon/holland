extends GutTest

const CombatAiScript := preload("res://src/combat/combat_ai.gd")
const EncounterRegistryScript := preload("res://src/data/encounter_registry.gd")
const UnitRegistryScript := preload("res://src/data/unit_registry.gd")

const TURN_CAP := 200


func test_registered_encounters_finish_under_turn_cap() -> void:
	for encounter_id: String in EncounterRegistryScript.get_all_encounter_ids():
		var replay := _run_auto_battle(encounter_id)

		assert_ne(
			replay.get("outcome"),
			"ongoing",
			"%s should finish before the smoke test turn cap." % encounter_id
		)
		assert_lt(replay.get("turns"), TURN_CAP)
		assert_gt(replay.get("events").size(), 0)


func test_same_seed_encounters_replay_same_event_flow() -> void:
	for encounter_id: String in EncounterRegistryScript.get_all_encounter_ids():
		var first := _run_auto_battle(encounter_id)
		var second := _run_auto_battle(encounter_id)

		assert_eq(second.get("outcome"), first.get("outcome"), encounter_id)
		assert_eq(second.get("turns"), first.get("turns"), encounter_id)
		assert_eq(second.get("events"), first.get("events"), encounter_id)


func _run_auto_battle(encounter_id: String) -> Dictionary:
	var encounter = EncounterRegistryScript.get_encounter(encounter_id)
	var state := CombatState.new()
	state.start_encounter(
		UnitRegistryScript.player_units(),
		encounter.create_enemy_units(),
		_create_open_cells(),
		encounter.encounter_seed
	)

	var events: Array[String] = []
	var turn_count := 0
	while state.get_outcome() == "ongoing" and turn_count < TURN_CAP:
		var active := state.get_active_unit()
		if active == null:
			events.append("stalled:null_active_unit")
			break
		events.append(_format_turn_event(state, active))
		var action: Dictionary = CombatAiScript.select_action(active, state)
		var turn_was_consumed := _apply_ai_action(state, active, action, events)
		if not turn_was_consumed:
			state.end_turn()
		turn_count += 1

	return {
		"outcome": state.get_outcome(),
		"turns": turn_count,
		"events": events,
	}


func _apply_ai_action(
	state: CombatState, active: CombatUnit, action: Dictionary, events: Array[String]
) -> bool:
	if action.is_empty():
		return false
	var move_cell: Vector2i = action.get("move_cell", active.position)
	if move_cell != active.position:
		state.move_unit(active.id, move_cell)
		if state.get_last_move_result().get("escaped", false):
			events.append("%s:escaped" % active.id)
			return true
	var target_id: String = action.get("attack_target_id", "")
	if target_id.is_empty():
		return false
	var skill_id: String = action.get("attack_skill_id", CombatSkillRegistry.BASIC_ATTACK_ID)
	var result := state.attack(active.id, target_id, skill_id)
	if result.is_empty():
		return false
	events.append(_format_attack_event(active.id, target_id, result))
	return false


func _format_turn_event(state: CombatState, active: CombatUnit) -> String:
	return "%d:%s:%s:%d:%d:%d" % [
		state.round_number,
		active.id,
		active.get_morale_state_name(),
		active.hp,
		active.action_points,
		active.fatigue,
	]


func _format_attack_event(attacker_id: String, target_id: String, result: Dictionary) -> String:
	return "%s>%s:%s:%s:%s:%d:%d:%d:%s" % [
		attacker_id,
		target_id,
		result.get("skill_id", ""),
		str(result.get("hit", false)),
		result.get("body_part", ""),
		result.get("roll", 0),
		result.get("armor_damage", 0),
		result.get("hp_damage", 0),
		str(result.get("killed", false)),
	]


func _create_open_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x: int in range(0, 9):
		for y: int in range(0, 9):
			cells.append(Vector2i(x, y))
	return cells
