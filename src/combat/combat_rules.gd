class_name CombatRules

const TURN_FATIGUE_RECOVERY: int = 15
const ATTACK_FATIGUE_COST: int = 30
const BASIC_ATTACK_AP_COST: int = 4
const MIN_HIT_CHANCE: int = 5
const MAX_HIT_CHANCE: int = 95


## Returns passable cells the unit can move to this turn.
static func get_legal_moves(unit: CombatUnit, board: CombatBoard) -> Array[Vector2i]:
	if not unit.alive or unit.has_acted or unit.action_points <= 0:
		return []
	if unit.fatigue >= unit.max_fatigue:
		return []
	return get_reachable_by_ap(unit, board)


static func get_reachable_by_ap(unit: CombatUnit, board: CombatBoard) -> Array[Vector2i]:
	var best_cost: Dictionary = {}
	var best_fatigue_cost: Dictionary = {}
	best_cost[unit.position] = 0
	best_fatigue_cost[unit.position] = 0
	var frontier: Array[Vector2i] = [unit.position]

	while not frontier.is_empty():
		var current := frontier.pop_front() as Vector2i
		for neighbor: Vector2i in board.get_neighbors(current):
			if not board.is_passable(neighbor):
				continue
			var next_ap_cost: int = (
				best_cost[current] + board.get_step_ap_cost(current, neighbor, unit)
			)
			var next_fatigue_cost: int = (
				best_fatigue_cost[current] + board.get_step_fatigue_cost(current, neighbor, unit)
			)
			if (
				next_ap_cost > unit.action_points
				or unit.fatigue + next_fatigue_cost > unit.max_fatigue
			):
				continue
			if (
				best_cost.has(neighbor)
				and best_cost[neighbor] <= next_ap_cost
				and best_fatigue_cost[neighbor] <= next_fatigue_cost
			):
				continue
			best_cost[neighbor] = next_ap_cost
			best_fatigue_cost[neighbor] = next_fatigue_cost
			frontier.append(neighbor)

	var result: Array[Vector2i] = []
	for cell: Vector2i in best_cost.keys():
		if cell != unit.position:
			result.append(cell)
	return result


## Returns ids of living enemies adjacent to attacker.
static func get_attack_targets(
	attacker: CombatUnit, board: CombatBoard, all_units: Array[CombatUnit]
) -> Array[String]:
	if not attacker.alive or attacker.has_acted:
		return []
	if attacker.action_points < BASIC_ATTACK_AP_COST:
		return []
	if attacker.fatigue + ATTACK_FATIGUE_COST > attacker.max_fatigue:
		return []

	var result: Array[String] = []
	for neighbor: Vector2i in board.get_neighbors(attacker.position):
		if not board.is_melee_reachable(attacker.position, neighbor):
			continue
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
	attacker: CombatUnit,
	defender: CombatUnit,
	rng: RandomNumberGenerator,
	board: CombatBoard = null
) -> Dictionary:
	var hit_chance := calculate_hit_chance(attacker, defender, board)
	var roll := rng.randi_range(1, 100)
	var hit := roll <= hit_chance
	var raw_damage := attacker.damage
	var hp_damage := raw_damage if hit else 0

	return {
		"hit": hit,
		"hit_chance": hit_chance,
		"roll": roll,
		"raw_damage": raw_damage,
		"hp_damage": hp_damage,
	}


static func calculate_hit_chance(
	attacker: CombatUnit, defender: CombatUnit, board: CombatBoard = null
) -> int:
	var defense := defender.melee_defense
	if defense > 50:
		@warning_ignore("integer_division")
		defense = 50 + ((defense - 50) / 2)
	var chance := attacker.melee_skill - defense
	if board != null:
		var height_delta := (
			board.get_height(attacker.position) - board.get_height(defender.position)
		)
		if height_delta > 0:
			chance += 10
		elif height_delta < 0:
			chance -= 10 * abs(height_delta)
	return clampi(chance, MIN_HIT_CHANCE, MAX_HIT_CHANCE)


static func get_path_ap_cost(path: Array[Vector2i], unit: CombatUnit, board: CombatBoard) -> int:
	var cost := 0
	for i: int in range(1, path.size()):
		cost += board.get_step_ap_cost(path[i - 1], path[i], unit)
	return cost


static func get_path_fatigue_cost(
	path: Array[Vector2i], unit: CombatUnit, board: CombatBoard
) -> int:
	var cost := 0
	for i: int in range(1, path.size()):
		cost += board.get_step_fatigue_cost(path[i - 1], path[i], unit)
	return cost


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
