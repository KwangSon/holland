class_name CombatState

var round_number: int = 1

var _board: CombatBoard
var _units: Dictionary = {}  # unit_id → CombatUnit
var _turn_order: Array[String] = []  # unit_ids sorted by initiative
var _turn_started_round: Dictionary = {}  # unit_id → round_number
var _turn_index: int = 0
var _rng: RandomNumberGenerator


func start_encounter(
	player_units: Array[CombatUnit],
	enemy_units: Array[CombatUnit],
	valid_cells: Array[Vector2i],
	encounter_seed: int
) -> void:
	_board = CombatBoard.new()
	_board.setup(valid_cells)
	_start_encounter_on_board(player_units, enemy_units, encounter_seed)


func start_encounter_tiles(
	player_units: Array[CombatUnit],
	enemy_units: Array[CombatUnit],
	tile_data_by_cell: Dictionary,
	encounter_seed: int
) -> void:
	_board = CombatBoard.new()
	_board.setup_tiles(tile_data_by_cell)
	_start_encounter_on_board(player_units, enemy_units, encounter_seed)


func _start_encounter_on_board(
	player_units: Array[CombatUnit], enemy_units: Array[CombatUnit], encounter_seed: int
) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = encounter_seed

	_units.clear()
	_turn_started_round.clear()
	var all: Array[CombatUnit] = []
	for unit: CombatUnit in player_units:
		_units[unit.id] = unit
		_board.set_occupied(unit.position, unit.id)
		all.append(unit)
	for unit: CombatUnit in enemy_units:
		_units[unit.id] = unit
		_board.set_occupied(unit.position, unit.id)
		all.append(unit)

	_build_turn_order(all)
	_turn_index = 0
	_start_unit_turn(_get_active_ref(), 0)


func get_active_unit() -> CombatUnit:
	if _turn_order.is_empty():
		return null
	return _units.get(_turn_order[_turn_index], null)


func get_all_units() -> Array[CombatUnit]:
	var result: Array[CombatUnit] = []
	for unit: CombatUnit in _units.values():
		result.append(unit)
	return result


func get_board() -> CombatBoard:
	return _board


func get_legal_moves(unit_id: String) -> Array[Vector2i]:
	var unit: CombatUnit = _units.get(unit_id, null)
	if unit == null or not _is_active_unit_id(unit_id):
		return []
	return CombatRules.get_legal_moves(unit, _board)


func get_attack_targets(unit_id: String) -> Array[String]:
	var unit: CombatUnit = _units.get(unit_id, null)
	if unit == null or not _is_active_unit_id(unit_id):
		return []
	return CombatRules.get_attack_targets(unit, _board, get_all_units())


func move_unit(unit_id: String, target: Vector2i) -> bool:
	var unit: CombatUnit = _units.get(unit_id, null)
	if unit == null or not unit.alive or not _is_active_unit_id(unit_id):
		return false
	if not target in CombatRules.get_legal_moves(unit, _board):
		return false
	var path := _board.find_path(unit.position, target)
	if path.size() < 2:
		return false
	if _path_leaves_hostile_zoc(unit, path):
		return false
	var ap_cost := CombatRules.get_path_ap_cost(path, unit, _board)
	var fatigue_cost := CombatRules.get_path_fatigue_cost(path, unit, _board)
	if ap_cost > unit.action_points or unit.fatigue + fatigue_cost > unit.max_fatigue:
		return false
	_board.clear_occupied(unit.position)
	unit.position = target
	_board.set_occupied(target, unit_id)
	unit.action_points -= ap_cost
	unit.fatigue += fatigue_cost
	return true


## Returns the roll_attack result dict, plus "killed" key.
func attack(attacker_id: String, defender_id: String) -> Dictionary:
	var attacker: CombatUnit = _units.get(attacker_id, null)
	var defender: CombatUnit = _units.get(defender_id, null)
	if attacker == null or defender == null:
		return {}
	if not attacker.alive or not defender.alive or not _is_active_unit_id(attacker_id):
		return {}
	if not defender_id in CombatRules.get_attack_targets(attacker, _board, get_all_units()):
		return {}

	var result := CombatRules.roll_attack(attacker, defender, _rng, _board)
	CombatRules.apply_attack_result(defender, result)
	result["killed"] = not defender.alive
	attacker.action_points -= CombatRules.BASIC_ATTACK_AP_COST
	attacker.fatigue += CombatRules.ATTACK_FATIGUE_COST

	if not defender.alive:
		_board.clear_occupied(defender.position)
		var dead_idx := _turn_order.find(defender_id)
		_turn_order.erase(defender_id)
		if dead_idx != -1 and dead_idx < _turn_index:
			_turn_index -= 1
		if not _turn_order.is_empty():
			_turn_index = _turn_index % _turn_order.size()

	return result


func end_turn() -> void:
	if _turn_order.is_empty():
		return
	if _turn_index + 1 >= _turn_order.size():
		round_number += 1
		_build_turn_order(_get_living_units())
		_turn_index = 0
	else:
		_turn_index += 1
	var active := get_active_unit()
	if active != null:
		_start_unit_turn(active, CombatRules.TURN_FATIGUE_RECOVERY)


## Returns units of the given team remaining to act in the current turn cycle.
func get_remaining_team_queue(team: String) -> Array[CombatUnit]:
	var result: Array[CombatUnit] = []
	for i: int in range(_turn_index, _turn_order.size()):
		var unit: CombatUnit = _units.get(_turn_order[i], null)
		if unit != null and unit.alive and unit.team == team:
			result.append(unit)
	return result


## Defers the active player unit to the end of the remaining player queue.
func wait_turn() -> void:
	if _turn_order.is_empty():
		return
	var active := get_active_unit()
	if active == null or active.team != "player":
		return
	var current_id := _turn_order[_turn_index]
	var last_player_pos := _turn_index
	for i: int in range(_turn_index + 1, _turn_order.size()):
		var u: CombatUnit = _units.get(_turn_order[i], null)
		if u != null and u.team == "player":
			last_player_pos = i
	if last_player_pos == _turn_index:
		end_turn()
		return
	_turn_order.remove_at(_turn_index)
	_turn_order.insert(last_player_pos, current_id)
	var next := get_active_unit()
	if next != null:
		_start_unit_turn(next, CombatRules.TURN_FATIGUE_RECOVERY)


## Skips all remaining player turns and advances to the next enemy unit.
func end_player_phase() -> void:
	if _turn_order.is_empty():
		return
	var active := get_active_unit()
	if active == null or active.team != "player":
		return
	var found := false
	for i: int in range(_turn_index, _turn_order.size()):
		var u: CombatUnit = _units.get(_turn_order[i], null)
		if u != null and u.team != "player":
			_turn_index = i
			found = true
			break
	if not found:
		round_number += 1
		_build_turn_order(_get_living_units())
		_turn_index = 0
	var next := get_active_unit()
	if next != null:
		_start_unit_turn(next, CombatRules.TURN_FATIGUE_RECOVERY)


func get_outcome() -> String:
	return CombatRules.check_outcome(get_all_units())


func _build_turn_order(units: Array[CombatUnit]) -> void:
	var living: Array[CombatUnit] = []
	for unit: CombatUnit in units:
		if unit.alive:
			living.append(unit)
	living.sort_custom(
		func(a: CombatUnit, b: CombatUnit) -> bool:
			var initiative_a := a.get_current_initiative()
			var initiative_b := b.get_current_initiative()
			if initiative_a == initiative_b:
				return a.id < b.id
			return initiative_a > initiative_b
	)

	_turn_order.clear()
	for unit: CombatUnit in living:
		_turn_order.append(unit.id)


func _get_living_units() -> Array[CombatUnit]:
	var result: Array[CombatUnit] = []
	for unit: CombatUnit in _units.values():
		if unit.alive:
			result.append(unit)
	return result


func _is_active_unit_id(unit_id: String) -> bool:
	var active := get_active_unit()
	return active != null and active.id == unit_id


func _start_unit_turn(unit: CombatUnit, fatigue_recovery: int) -> void:
	if unit == null:
		return
	if _turn_started_round.get(unit.id, 0) == round_number:
		return
	unit.begin_turn(fatigue_recovery)
	_turn_started_round[unit.id] = round_number


func _path_leaves_hostile_zoc(unit: CombatUnit, path: Array[Vector2i]) -> bool:
	var all_units := get_all_units()
	for i: int in range(1, path.size()):
		var step_from := path[i - 1]
		var controllers := CombatRules.get_hostile_zoc_controllers(
			unit, step_from, all_units, _board
		)
		if not controllers.is_empty():
			return true
	return false


func _get_active_ref() -> CombatUnit:
	return _units[_turn_order[_turn_index]]
