class_name CombatAi


static func select_action(active: CombatUnit, state: CombatState) -> Dictionary:
	if active == null or not active.alive:
		return {}
	var board := state.get_board()
	if active.is_fleeing():
		return {
			"move_cell": _select_flee_cell(active, state),
			"attack_target_id": "",
			"attack_skill_id": "",
		}
	var all_units := state.get_all_units()
	var attack_skill_ids := _get_attack_skill_ids(active)
	var current_attack := _select_best_attack(
		active, active.position, board, all_units, attack_skill_ids
	)
	if not current_attack.is_empty():
		return {
			"move_cell": active.position,
			"attack_target_id": current_attack["target_id"],
			"attack_skill_id": current_attack["skill_id"],
		}

	var best_score := _score_move(active.position, active, board, all_units, 0)
	var best_action := {"move_cell": active.position, "attack_target_id": "", "attack_skill_id": ""}
	for cell: Vector2i in state.get_legal_moves(active.id):
		var path := board.find_path(active.position, cell)
		var path_ap_cost := CombatRules.get_path_ap_cost(path, active, board)
		var path_fatigue_cost := CombatRules.get_path_fatigue_cost(path, active, board)
		var attack := _select_best_attack(
			active, cell, board, all_units, attack_skill_ids, path_ap_cost, path_fatigue_cost
		)
		var zoc_risk := _get_path_zoc_risk(active, cell, board, all_units)
		var score := _score_move(cell, active, board, all_units, zoc_risk)
		if not attack.is_empty():
			score += attack["score"] + 10000
		if score > best_score:
			best_score = score
			best_action = {
				"move_cell": cell,
				"attack_target_id": attack.get("target_id", ""),
				"attack_skill_id": attack.get("skill_id", ""),
			}
	return best_action


static func _select_flee_cell(active: CombatUnit, state: CombatState) -> Vector2i:
	var legal_moves := state.get_legal_moves(active.id)
	if legal_moves.is_empty():
		return active.position
	var best_cell := active.position
	var best_distance := _distance_to_board_edge(active.position, state.get_board())
	for cell: Vector2i in legal_moves:
		var distance := _distance_to_board_edge(cell, state.get_board())
		if distance < best_distance or (distance == best_distance and _is_cell_before(cell, best_cell)):
			best_distance = distance
			best_cell = cell
	return best_cell


static func _is_cell_before(a: Vector2i, b: Vector2i) -> bool:
	return a.x < b.x or (a.x == b.x and a.y < b.y)


static func _distance_to_board_edge(cell: Vector2i, board: CombatBoard) -> int:
	var valid_cells := board.get_valid_cells()
	var min_x := cell.x
	var max_x := cell.x
	var min_y := cell.y
	var max_y := cell.y
	for valid_cell: Vector2i in valid_cells:
		min_x = mini(min_x, valid_cell.x)
		max_x = maxi(max_x, valid_cell.x)
		min_y = mini(min_y, valid_cell.y)
		max_y = maxi(max_y, valid_cell.y)
	return mini(mini(cell.x - min_x, max_x - cell.x), mini(cell.y - min_y, max_y - cell.y))


static func _get_attack_skill_ids(unit: CombatUnit) -> Array[String]:
	var result: Array[String] = []
	for skill_id: String in unit.skill_ids:
		if skill_id in CombatSkillRegistry.get_attack_skill_ids():
			result.append(skill_id)
	if result.is_empty():
		result.append(CombatSkillRegistry.BASIC_ATTACK_ID)
	return result


static func _select_best_attack(
	active: CombatUnit,
	position: Vector2i,
	board: CombatBoard,
	all_units: Array[CombatUnit],
	attack_skill_ids: Array[String],
	action_point_cost: int = 0,
	fatigue_cost: int = 0
) -> Dictionary:
	var original_position := active.position
	var original_action_points := active.action_points
	var original_fatigue := active.fatigue
	active.position = position
	active.action_points -= action_point_cost
	active.fatigue += fatigue_cost
	var best_score := -999999
	var best_attack := {}
	for skill_id: String in attack_skill_ids:
		var skill: CombatSkillData = CombatSkillRegistry.get_skill(skill_id)
		var target_ids := CombatRules.get_attack_targets(active, board, all_units, skill)
		for target_id: String in target_ids:
			var defender := _find_unit(target_id, all_units)
			if defender == null:
				continue
			var preview := CombatRules.preview_attack(active, defender, board, skill, all_units)
			var score := _score_attack(preview, defender)
			if score > best_score:
				best_score = score
				best_attack = {"target_id": target_id, "skill_id": skill_id, "score": score}
	active.position = original_position
	active.action_points = original_action_points
	active.fatigue = original_fatigue
	return best_attack


static func _score_attack(preview: Dictionary, defender: CombatUnit) -> int:
	var body_hp_damage: int = preview.get("body_hp_damage", 0)
	var body_armor_damage: int = preview.get("body_armor_damage", 0)
	var score: int = preview.get("hit_chance", 0) * 10 + body_hp_damage * 5 + body_armor_damage
	if body_hp_damage >= defender.hp:
		score += 1000
	return score


static func _score_move(
	cell: Vector2i,
	active: CombatUnit,
	board: CombatBoard,
	all_units: Array[CombatUnit],
	zoc_risk: int
) -> int:
	var nearest_distance := 999999
	for unit: CombatUnit in all_units:
		if unit.team == active.team or not unit.alive:
			continue
		nearest_distance = mini(nearest_distance, board.hex_distance(cell, unit.position))
	return -nearest_distance * 10 - zoc_risk * 1000


static func _get_path_zoc_risk(
	active: CombatUnit, destination: Vector2i, board: CombatBoard, all_units: Array[CombatUnit]
) -> int:
	var path := board.find_path(active.position, destination)
	var risk := 0
	for i: int in range(1, path.size()):
		risk += CombatRules.get_hostile_zoc_controllers(
			active, path[i - 1], all_units, board
		).size()
	return risk


static func _find_unit(unit_id: String, all_units: Array[CombatUnit]) -> CombatUnit:
	for unit: CombatUnit in all_units:
		if unit.id == unit_id:
			return unit
	return null
