class_name CombatRules

const CombatSkillDataScript := preload("res://src/combat/combat_skill_data.gd")

const TURN_FATIGUE_RECOVERY: int = 15
const MIN_HIT_CHANCE: int = 5
const MAX_HIT_CHANCE: int = 95
const ARMOR_DAMAGE_PERCENT: int = 100
const ARMOR_HP_DAMAGE_REDUCTION_PERCENT: int = 10
const HEAD_HP_DAMAGE_PERCENT: int = 150


## Returns passable cells the unit can move to this turn.
static func get_legal_moves(unit: CombatUnit, board: CombatBoard) -> Array[Vector2i]:
	if not unit.alive or unit.action_points <= 0:
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
	attacker: CombatUnit, board: CombatBoard, all_units: Array[CombatUnit], skill = null
) -> Array[String]:
	var attack_skill = _skill_or_basic(skill)
	if not attacker.alive:
		return []
	if attacker.action_points < attack_skill.action_point_cost:
		return []
	if attacker.fatigue + attack_skill.fatigue_cost > attacker.max_fatigue:
		return []

	var result: Array[String] = []
	for unit: CombatUnit in all_units:
		if unit.team == attacker.team or not unit.alive:
			continue
		if _is_target_in_skill_range(attacker, unit, board, attack_skill):
			result.append(unit.id)
	return result


static func get_zoc_cells(unit: CombatUnit, board: CombatBoard) -> Array[Vector2i]:
	if not unit.alive:
		return []

	var result: Array[Vector2i] = []
	for cell: Vector2i in board.get_neighbors(unit.position):
		if board.is_melee_reachable(unit.position, cell):
			result.append(cell)
	return result


static func get_hostile_zoc_controllers(
	unit: CombatUnit, cell: Vector2i, all_units: Array[CombatUnit], board: CombatBoard
) -> Array[CombatUnit]:
	var result: Array[CombatUnit] = []
	for other: CombatUnit in all_units:
		if other.id == unit.id or other.team == unit.team or not other.alive:
			continue
		if cell in get_zoc_cells(other, board):
			result.append(other)
	return result


## Rolls an attack. Simple melee combat: 100% hit chance, flat damage.
## Returns: {hit, raw_damage, hp_damage}
static func roll_attack(
	attacker: CombatUnit,
	defender: CombatUnit,
	rng: RandomNumberGenerator,
	board: CombatBoard = null,
	skill = null
) -> Dictionary:
	var attack_skill = _skill_or_basic(skill)
	var hit_chance: int = calculate_hit_chance(attacker, defender, board, attack_skill)
	var roll := rng.randi_range(1, 100)
	var hit := roll <= hit_chance
	var body_part := "body"
	if hit:
		body_part = roll_body_part(attacker, rng, attack_skill)
	var raw_damage := _percent_of(attacker.damage, attack_skill.damage_percent)
	var damage_result := (
		roll_damage(attacker, defender, raw_damage, body_part, attack_skill) if hit else {}
	)

	return {
		"hit": hit,
		"hit_chance": hit_chance,
		"roll": roll,
		"skill_id": attack_skill.id,
		"body_part": body_part,
		"raw_damage": raw_damage,
		"armor_damage": damage_result.get("armor_damage", 0),
		"hp_damage": damage_result.get("hp_damage", 0),
	}


static func calculate_hit_chance(
	attacker: CombatUnit, defender: CombatUnit, board: CombatBoard = null, skill = null
) -> int:
	var attack_skill = _skill_or_basic(skill)
	var defense: int = defender.melee_defense
	if defense > 50:
		@warning_ignore("integer_division")
		defense = 50 + ((defense - 50) / 2)
	var chance: int = attacker.melee_skill - defense + attack_skill.hit_modifier
	if board != null:
		var height_delta := (
			board.get_height(attacker.position) - board.get_height(defender.position)
		)
		if height_delta > 0:
			chance += 10
		elif height_delta < 0:
			chance -= 10 * abs(height_delta)
	return clampi(chance, MIN_HIT_CHANCE, MAX_HIT_CHANCE)


static func roll_body_part(
	attacker: CombatUnit, rng: RandomNumberGenerator, skill = null
) -> String:
	var attack_skill = _skill_or_basic(skill)
	var head_chance := clampi(attacker.chance_to_hit_head + attack_skill.head_hit_modifier, 0, 100)
	return "head" if rng.randi_range(1, 100) <= head_chance else "body"


static func roll_damage(
	attacker: CombatUnit, defender: CombatUnit, raw_damage: int, body_part: String, skill = null
) -> Dictionary:
	var attack_skill = _skill_or_basic(skill)
	var armor_before: int = defender.head_armor if body_part == "head" else defender.body_armor
	var armor_damage: int = mini(
		armor_before, _percent_of(raw_damage, attack_skill.armor_damage_percent)
	)
	var armor_after := maxi(0, armor_before - armor_damage)
	var hp_damage := raw_damage

	if armor_before > 0:
		var armor_penetration := clampi(
			attacker.armor_penetration + attack_skill.armor_penetration_modifier, 0, 100
		)
		var penetrating_damage := _percent_of(raw_damage, armor_penetration)
		var overflow_damage := floori(float(maxi(0, raw_damage - armor_before)) / 2.0)
		var armor_reduction := _percent_of(armor_after, ARMOR_HP_DAMAGE_REDUCTION_PERCENT)
		hp_damage = maxi(0, penetrating_damage + overflow_damage - armor_reduction)

	if body_part == "head":
		hp_damage = _percent_of(hp_damage, HEAD_HP_DAMAGE_PERCENT)

	return {
		"body_part": body_part,
		"armor_before": armor_before,
		"armor_damage": armor_damage,
		"armor_after": armor_after,
		"hp_damage": hp_damage,
	}


static func _percent_of(value: int, percent: int) -> int:
	return floori(float(value) * float(percent) / 100.0)


static func get_basic_attack_skill():
	return CombatSkillDataScript.basic_attack()


static func _skill_or_basic(skill):
	return skill if skill != null else get_basic_attack_skill()


static func _is_target_in_skill_range(
	attacker: CombatUnit, defender: CombatUnit, board: CombatBoard, skill
) -> bool:
	if skill.attack_range <= 1:
		return board.is_melee_reachable(attacker.position, defender.position)
	return board.hex_distance(attacker.position, defender.position) <= skill.attack_range


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
	var body_part: String = result.get("body_part", "body")
	var armor_damage: int = result.get("armor_damage", 0)
	if body_part == "head":
		defender.head_armor = maxi(0, defender.head_armor - armor_damage)
	else:
		defender.body_armor = maxi(0, defender.body_armor - armor_damage)
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
