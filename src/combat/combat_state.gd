class_name CombatState

var _board: CombatBoard
var _units: Dictionary = {}  # unit_id → CombatUnit
var _turn_order: Array[String] = []  # unit_ids sorted by initiative
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

	_rng = RandomNumberGenerator.new()
	_rng.seed = encounter_seed

	_units.clear()
	var all: Array[CombatUnit] = []
	for unit: CombatUnit in player_units:
		_units[unit.id] = unit
		_board.set_occupied(unit.position, unit.id)
		all.append(unit)
	for unit: CombatUnit in enemy_units:
		_units[unit.id] = unit
		_board.set_occupied(unit.position, unit.id)
		all.append(unit)

	all.sort_custom(func(a: CombatUnit, b: CombatUnit) -> bool: return a.initiative > b.initiative)
	_turn_order.clear()
	for unit: CombatUnit in all:
		_turn_order.append(unit.id)

	_turn_index = 0
	_get_active_ref().ap = _get_active_ref().max_ap


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
	if unit == null:
		return []
	return CombatRules.get_legal_moves(unit, _board)


func get_attack_targets(unit_id: String) -> Array[String]:
	var unit: CombatUnit = _units.get(unit_id, null)
	if unit == null:
		return []
	return CombatRules.get_attack_targets(unit, _board, get_all_units())


func move_unit(unit_id: String, target: Vector2i) -> bool:
	var unit: CombatUnit = _units.get(unit_id, null)
	if unit == null or not unit.alive or unit.ap <= 0:
		return false
	if not target in CombatRules.get_legal_moves(unit, _board):
		return false
	_board.clear_occupied(unit.position)
	unit.position = target
	_board.set_occupied(target, unit_id)
	unit.ap -= 1
	return true


## Returns the roll_attack result dict, plus "killed" key.
func attack(attacker_id: String, defender_id: String) -> Dictionary:
	var attacker: CombatUnit = _units.get(attacker_id, null)
	var defender: CombatUnit = _units.get(defender_id, null)
	if attacker == null or defender == null:
		return {}
	if not attacker.alive or not defender.alive or attacker.ap <= 0:
		return {}
	if not defender_id in CombatRules.get_attack_targets(attacker, _board, get_all_units()):
		return {}

	var result := CombatRules.roll_attack(attacker, defender, _rng)
	CombatRules.apply_attack_result(defender, result)
	result["killed"] = not defender.alive
	attacker.ap -= 1

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
	_turn_index = (_turn_index + 1) % _turn_order.size()
	var active := get_active_unit()
	if active != null:
		active.ap = active.max_ap


func get_outcome() -> String:
	return CombatRules.check_outcome(get_all_units())


func _get_active_ref() -> CombatUnit:
	return _units[_turn_order[_turn_index]]
