extends GutTest


func _make_unit(overrides: Dictionary = {}) -> CombatUnit:
	var defaults := {
		"id": "u1",
		"display_name": "Test",
		"team": "player",
		"position": Vector2i(0, 0),
		"max_hp": 30,
		"max_action_points": 9,
		"max_fatigue": 100,
		"melee_skill": 0,
		"ranged_skill": 60,
	}
	defaults.merge(overrides, true)
	return CombatUnit.create(defaults)


func _make_line_board(length: int) -> CombatBoard:
	var tiles := {}
	for x: int in range(length):
		tiles[Vector2i(x, 0)] = {"terrain": CombatTileData.TerrainType.PLAIN, "height": 0}
	var board := CombatBoard.new()
	board.setup_tiles(tiles)
	return board


func test_ranged_hit_uses_ranged_stats_and_distance_penalty() -> void:
	var board := _make_line_board(3)
	var attacker := _make_unit({"id": "a", "position": Vector2i(0, 0)})
	var defender := _make_unit(
		{
			"id": "d",
			"team": "enemy",
			"position": Vector2i(2, 0),
			"melee_defense": 95,
			"ranged_defense": 20,
		}
	)
	var skill: CombatSkillData = CombatSkillRegistry.get_skill(CombatSkillRegistry.RANGED_SHOT_ID)

	assert_eq(CombatRules.calculate_hit_chance(attacker, defender, board, skill), 30)


func test_high_ground_extends_ranged_attack_range() -> void:
	var board := _make_line_board(8)
	var attacker := _make_unit({"id": "a", "position": Vector2i(0, 0)})
	var defender := _make_unit({"id": "d", "team": "enemy", "position": Vector2i(7, 0)})
	var skill: CombatSkillData = CombatSkillRegistry.get_skill(CombatSkillRegistry.RANGED_SHOT_ID)

	assert_eq(CombatRules.get_attack_targets(attacker, board, [attacker, defender], skill), [])

	board.set_height(attacker.position, 2)

	assert_eq(CombatRules.get_attack_targets(attacker, board, [attacker, defender], skill), ["d"])
