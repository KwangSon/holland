class_name CombatRules

const CombatSkillDataScript := preload("res://src/combat/combat_skill_data.gd")
const CombatSkillRegistryScript := preload("res://src/combat/combat_skill_registry.gd")

const TURN_FATIGUE_RECOVERY: int = 15
const MIN_HIT_CHANCE: int = 5
const MAX_HIT_CHANCE: int = 95
const SURROUND_DEFENSE_PENALTY_PER_UNIT: int = 5
const ARMOR_DAMAGE_PERCENT: int = 100
const ARMOR_HP_DAMAGE_REDUCTION_PERCENT: int = 10
const HEAD_HP_DAMAGE_PERCENT: int = 150


## Returns passable cells the unit can move to this turn.
static func get_legal_moves(
	unit: CombatUnit, board: CombatBoard, movement_skill = null
) -> Array[Vector2i]:
	var skill = _skill_or_null(movement_skill)
	if not unit.alive or unit.action_points <= 0:
		return []
	if unit.fatigue >= unit.max_fatigue:
		return []
	if skill != null and (
		unit.action_points < skill.action_point_cost
		or unit.fatigue + skill.fatigue_cost > unit.max_fatigue
	):
		return []
	return get_reachable_by_ap(unit, board, skill)


static func get_reachable_by_ap(
	unit: CombatUnit, board: CombatBoard, movement_skill = null
) -> Array[Vector2i]:
	var skill = _skill_or_null(movement_skill)
	var action_point_budget := unit.action_points
	var fatigue_budget := unit.max_fatigue - unit.fatigue
	if skill != null:
		action_point_budget -= skill.action_point_cost
		fatigue_budget -= skill.fatigue_cost
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
			if next_ap_cost > action_point_budget or next_fatigue_cost > fatigue_budget:
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
	if attacker.ammo < attack_skill.ammo_cost:
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


static func skill_ignores_zoc(skill) -> bool:
	var resolved_skill = _skill_or_null(skill)
	return resolved_skill != null and "zoc_ignore" in resolved_skill.tags


## Rolls an attack and returns a stable combat action result dictionary.
static func roll_attack(
	attacker: CombatUnit,
	defender: CombatUnit,
	rng: RandomNumberGenerator,
	board: CombatBoard = null,
	skill = null,
	all_units: Array[CombatUnit] = []
) -> Dictionary:
	var attack_skill = _skill_or_basic(skill)
	var hit_chance: int = calculate_hit_chance(attacker, defender, board, attack_skill, all_units)
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
		"skill_display_name": attack_skill.display_name,
		"action_point_cost": attack_skill.action_point_cost,
		"fatigue_cost": attack_skill.fatigue_cost,
		"ammo_cost": attack_skill.ammo_cost,
		"body_part": body_part,
		"raw_damage": raw_damage,
		"armor_before": damage_result.get("armor_before", 0),
		"armor_damage": damage_result.get("armor_damage", 0),
		"armor_after": damage_result.get("armor_after", 0),
		"hp_damage": damage_result.get("hp_damage", 0),
		"killed": false,
	}


static func calculate_hit_chance(
	attacker: CombatUnit,
	defender: CombatUnit,
	board: CombatBoard = null,
	skill = null,
	all_units: Array[CombatUnit] = []
) -> int:
	var attack_skill = _skill_or_basic(skill)
	var is_ranged := _is_ranged_skill(attack_skill)
	var defense: int = defender.ranged_defense if is_ranged else defender.melee_defense
	if defense > 50:
		@warning_ignore("integer_division")
		defense = 50 + ((defense - 50) / 2)
	if not is_ranged:
		defense = maxi(
			0, defense - _get_surround_defense_penalty(attacker, defender, board, all_units)
		)
	var attack_stat: int = attacker.ranged_skill if is_ranged else attacker.melee_skill
	var chance: int = attack_stat - defense + attack_skill.hit_modifier
	if board != null:
		var height_delta := (
			board.get_height(attacker.position) - board.get_height(defender.position)
		)
		if height_delta > 0:
			chance += 10
		elif height_delta < 0:
			chance -= 10 * abs(height_delta)
		chance -= _get_distance_hit_penalty(attacker, defender, board, attack_skill)
	return clampi(chance, MIN_HIT_CHANCE, MAX_HIT_CHANCE)


static func preview_attack(
	attacker: CombatUnit,
	defender: CombatUnit,
	board: CombatBoard = null,
	skill = null,
	all_units: Array[CombatUnit] = []
) -> Dictionary:
	var attack_skill = _skill_or_basic(skill)
	var hit_chance := calculate_hit_chance(attacker, defender, board, attack_skill, all_units)
	var raw_damage := _percent_of(attacker.damage, attack_skill.damage_percent)
	var body_damage := roll_damage(attacker, defender, raw_damage, "body", attack_skill)
	var head_damage := roll_damage(attacker, defender, raw_damage, "head", attack_skill)
	return {
		"hit_chance": hit_chance,
		"skill_id": attack_skill.id,
		"skill_display_name": attack_skill.display_name,
		"raw_damage": raw_damage,
		"body_armor_damage": body_damage.get("armor_damage", 0),
		"body_hp_damage": body_damage.get("hp_damage", 0),
		"head_armor_damage": head_damage.get("armor_damage", 0),
		"head_hp_damage": head_damage.get("hp_damage", 0),
		"action_point_cost": attack_skill.action_point_cost,
		"fatigue_cost": attack_skill.fatigue_cost,
		"ammo_cost": attack_skill.ammo_cost,
	}


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
	return CombatSkillRegistryScript.get_skill(CombatSkillRegistryScript.BASIC_ATTACK_ID)


static func _skill_or_basic(skill):
	return skill if skill != null else get_basic_attack_skill()


static func _skill_or_null(skill):
	return skill if skill != null else null


static func _is_target_in_skill_range(
	attacker: CombatUnit, defender: CombatUnit, board: CombatBoard, skill
) -> bool:
	if skill.attack_range <= 1:
		return board.is_melee_reachable(attacker.position, defender.position)
	return (
		board.hex_distance(attacker.position, defender.position)
		<= _get_effective_attack_range(attacker, defender, board, skill)
		and _has_line_of_fire(attacker.position, defender.position, board, skill)
	)


static func _get_effective_attack_range(
	attacker: CombatUnit, defender: CombatUnit, board: CombatBoard, skill
) -> int:
	var attack_range: int = skill.attack_range
	if _is_ranged_skill(skill) and board.get_height(attacker.position) > board.get_height(
		defender.position
	):
		attack_range += board.get_height(attacker.position) - board.get_height(defender.position)
	return attack_range


static func _get_distance_hit_penalty(
	attacker: CombatUnit, defender: CombatUnit, board: CombatBoard, skill
) -> int:
	if not _is_ranged_skill(skill):
		return 0
	var distance := board.hex_distance(attacker.position, defender.position)
	var penalized_tiles: int = distance - 1 if skill.ignore_first_tile_for_distance else distance
	return maxi(0, penalized_tiles) * skill.distance_penalty_per_tile


static func _is_ranged_skill(skill) -> bool:
	return skill != null and "ranged" in skill.tags


static func _has_line_of_fire(
	attacker_cell: Vector2i, defender_cell: Vector2i, board: CombatBoard, skill
) -> bool:
	if not _is_ranged_skill(skill):
		return true
	for cell: Vector2i in _get_line_between_cells(attacker_cell, defender_cell, board):
		if board.get_tile_data(cell).is_blocked():
			return false
	return true


static func _get_line_between_cells(
	start: Vector2i, end: Vector2i, board: CombatBoard
) -> Array[Vector2i]:
	var distance := board.hex_distance(start, end)
	if distance <= 1:
		return []
	var start_cube := _offset_to_cube_float(start)
	var end_cube := _offset_to_cube_float(end)
	var result: Array[Vector2i] = []
	for i: int in range(1, distance):
		var t := float(i) / float(distance)
		var cube := start_cube.lerp(end_cube, t)
		var cell := _cube_round_to_offset(cube)
		if cell != start and cell != end and board.is_valid(cell) and not cell in result:
			result.append(cell)
	return result


static func _offset_to_cube_float(cell: Vector2i) -> Vector3:
	var q := float(cell.x)
	var r := float(cell.y - (cell.x >> 1))
	var s := -q - r
	return Vector3(q, s, r)


static func _cube_round_to_offset(cube: Vector3) -> Vector2i:
	var q := roundi(cube.x)
	var s := roundi(cube.y)
	var r := roundi(cube.z)
	var q_diff: float = abs(float(q) - cube.x)
	var s_diff: float = abs(float(s) - cube.y)
	var r_diff: float = abs(float(r) - cube.z)
	if q_diff > s_diff and q_diff > r_diff:
		q = -s - r
	elif s_diff > r_diff:
		s = -q - r
	else:
		r = -q - s
	return Vector2i(q, r + (q >> 1))


static func _get_surround_defense_penalty(
	attacker: CombatUnit, defender: CombatUnit, board: CombatBoard, all_units: Array[CombatUnit]
) -> int:
	if board == null or all_units.is_empty():
		return 0
	var supporting_attackers := 0
	for unit: CombatUnit in all_units:
		if unit.id == attacker.id or unit.id == defender.id:
			continue
		if unit.team != attacker.team or not unit.alive:
			continue
		if board.is_melee_reachable(unit.position, defender.position):
			supporting_attackers += 1
	return supporting_attackers * SURROUND_DEFENSE_PENALTY_PER_UNIT


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
