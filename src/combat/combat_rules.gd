class_name CombatRules

const MOVE_FATIGUE_COST: int = 20
const ATTACK_FATIGUE_COST: int = 30
const MOVE_RANGE: int = 3


## Returns passable cells the unit can move to this turn.
static func get_legal_moves(unit: CombatUnit, board: CombatBoard) -> Array[Vector2i]:
	if not unit.alive or unit.has_acted:
		return []
	if unit.fatigue + MOVE_FATIGUE_COST > unit.max_fatigue:
		return []
	return board.get_reachable(unit.position, MOVE_RANGE)


## Returns ids of living enemies adjacent to attacker.
static func get_attack_targets(
	attacker: CombatUnit, board: CombatBoard, all_units: Array[CombatUnit]
) -> Array[String]:
	if not attacker.alive or attacker.has_acted:
		return []
	if attacker.fatigue + ATTACK_FATIGUE_COST > attacker.max_fatigue:
		return []

	var result: Array[String] = []
	for neighbor: Vector2i in board.get_neighbors(attacker.position):
		if not board.occupied.has(neighbor):
			continue
		var uid: String = board.occupied[neighbor]
		for unit: CombatUnit in all_units:
			if unit.id == uid and unit.team != attacker.team and unit.alive:
				result.append(uid)
				break
	return result


## Rolls an attack. Simple melee combat: 100% hit chance, flat damage.
## Returns: {hit, raw_damage, hp_damage}
static func roll_attack(
	attacker: CombatUnit, _defender: CombatUnit, _rng: RandomNumberGenerator
) -> Dictionary:
	var raw_damage := attacker.damage
	var hp_damage := raw_damage

	return {
		"hit": true,
		"raw_damage": raw_damage,
		"hp_damage": hp_damage,
	}


## Applies roll_attack result to defender.
static func apply_attack_result(defender: CombatUnit, result: Dictionary) -> void:
	if not result.get("hit", false):
		return
	defender.hp = maxi(0, defender.hp - result.get("hp_damage", 0))
	if defender.hp <= 0:
		defender.alive = false


## Returns "victory", "defeat", or "ongoing".
static func check_outcome(all_units: Array[CombatUnit]) -> String:
	var player_alive := false
	var enemy_alive := false
	for unit: CombatUnit in all_units:
		if not unit.alive:
			continue
		if unit.team == "player":
			player_alive = true
		else:
			enemy_alive = true
	if not player_alive:
		return "defeat"
	if not enemy_alive:
		return "victory"
	return "ongoing"
