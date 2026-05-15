class_name CombatRules


## Returns passable cells the unit can move to this turn.
static func get_legal_moves(unit: CombatUnit, board: CombatBoard) -> Array[Vector2i]:
	if not unit.alive or unit.ap <= 0:
		return []
	return board.get_reachable(unit.position, unit.move_range)


## Returns ids of living enemies adjacent to attacker.
static func get_attack_targets(
	attacker: CombatUnit, board: CombatBoard, all_units: Array[CombatUnit]
) -> Array[String]:
	if not attacker.alive or attacker.ap <= 0:
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


## Hit probability clamped to [5, 95].
static func calc_hit_chance(attacker: CombatUnit, defender: CombatUnit) -> int:
	return clampi(attacker.melee_skill - defender.melee_defense + 50, 5, 95)


## Rolls an attack using the provided RNG. Pure — does NOT modify any unit.
## Returns: {hit, roll, raw_damage, armor_absorbed, hp_damage}
static func roll_attack(
	attacker: CombatUnit, defender: CombatUnit, rng: RandomNumberGenerator
) -> Dictionary:
	var hit_chance := calc_hit_chance(attacker, defender)
	var roll := rng.randi_range(1, 100)
	var hit := roll <= hit_chance

	var raw_damage := 0
	var armor_absorbed := 0
	var hp_damage := 0

	if hit:
		raw_damage = rng.randi_range(attacker.damage_min, attacker.damage_max)
		armor_absorbed = mini(defender.armor, raw_damage)
		hp_damage = raw_damage - armor_absorbed

	return {
		"hit": hit,
		"roll": roll,
		"raw_damage": raw_damage,
		"armor_absorbed": armor_absorbed,
		"hp_damage": hp_damage,
	}


## Applies roll_attack result to defender (reduces armor/hp, marks dead).
static func apply_attack_result(defender: CombatUnit, result: Dictionary) -> void:
	if not result.get("hit", false):
		return
	defender.armor = maxi(0, defender.armor - result.get("armor_absorbed", 0))
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
