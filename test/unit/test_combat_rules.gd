extends GutTest


func _make_unit(overrides: Dictionary = {}) -> CombatUnit:
	var defaults := {
		"id": "u1",
		"display_name": "Test",
		"team": "player",
		"position": Vector2i(0, 0),
		"max_hp": 30,
		"max_fatigue": 100,
		"damage": 10,
		"melee_skill": 95,
	}
	defaults.merge(overrides, true)
	return CombatUnit.create(defaults)


func _make_rng(rng_seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	return rng


# ----------------------------------------------------------
# roll_attack — determinism
# ----------------------------------------------------------


func test_roll_attack_deterministic_with_same_seed() -> void:
	var atk := _make_unit({"damage": 15})
	var def1 := _make_unit({"id": "d1", "team": "enemy"})
	var def2 := _make_unit({"id": "d2", "team": "enemy"})
	var result1 := CombatRules.roll_attack(atk, def1, _make_rng(42))
	var result2 := CombatRules.roll_attack(atk, def2, _make_rng(42))
	assert_eq(result1["hit"], result2["hit"])
	assert_eq(result1["raw_damage"], result2["raw_damage"])
	assert_eq(result1["hp_damage"], result2["hp_damage"])
	assert_eq(result1["hp_damage"], 15)


func test_roll_attack_does_not_modify_units() -> void:
	var atk := _make_unit()
	var def := _make_unit({"id": "d1", "team": "enemy", "hp": 30})
	CombatRules.roll_attack(atk, def, _make_rng(42))
	assert_eq(def.hp, 30)
	assert_true(def.alive)


# ----------------------------------------------------------
# apply_attack_result
# ----------------------------------------------------------


func test_apply_hit_reduces_hp() -> void:
	var def := _make_unit({"id": "d1", "team": "enemy", "hp": 30, "max_hp": 30})
	CombatRules.apply_attack_result(def, {"hit": true, "hp_damage": 10})
	assert_eq(def.hp, 20)


func test_apply_lethal_hit_marks_dead() -> void:
	var def := _make_unit({"id": "d1", "team": "enemy", "hp": 5, "max_hp": 30})
	var result := {"hit": true, "hp_damage": 10}
	CombatRules.apply_attack_result(def, result)
	assert_eq(def.hp, 0)
	assert_false(def.alive)


func test_apply_miss_does_nothing() -> void:
	var def := _make_unit({"id": "d1", "team": "enemy", "hp": 30, "max_hp": 30})
	var result := {"hit": false, "hp_damage": 0}
	CombatRules.apply_attack_result(def, result)
	assert_eq(def.hp, 30)


# ----------------------------------------------------------
# check_outcome
# ----------------------------------------------------------


func test_outcome_ongoing_with_both_teams_alive() -> void:
	var units: Array[CombatUnit] = [
		_make_unit({"id": "p1", "team": "player"}),
		_make_unit({"id": "e1", "team": "enemy"}),
	]
	assert_eq(CombatRules.check_outcome(units), "ongoing")


func test_outcome_victory_when_all_enemies_dead() -> void:
	var enemy := _make_unit({"id": "e1", "team": "enemy"})
	enemy.alive = false
	var units: Array[CombatUnit] = [
		_make_unit({"id": "p1", "team": "player"}),
		enemy,
	]
	assert_eq(CombatRules.check_outcome(units), "victory")


func test_outcome_defeat_when_all_players_dead() -> void:
	var player := _make_unit({"id": "p1", "team": "player"})
	player.alive = false
	var units: Array[CombatUnit] = [
		player,
		_make_unit({"id": "e1", "team": "enemy"}),
	]
	assert_eq(CombatRules.check_outcome(units), "defeat")


func test_outcome_defeat_when_all_units_dead() -> void:
	var p := _make_unit({"id": "p1", "team": "player"})
	var e := _make_unit({"id": "e1", "team": "enemy"})
	p.alive = false
	e.alive = false
	var units: Array[CombatUnit] = [p, e]
	assert_eq(CombatRules.check_outcome(units), "defeat")


# ----------------------------------------------------------
# movement and height rules
# ----------------------------------------------------------


func test_legal_moves_use_action_points() -> void:
	var board := CombatBoard.new()
	(
		board
		. setup_tiles(
			{
				Vector2i(0, 0): {"terrain": CombatTileData.TerrainType.PLAIN, "height": 0},
				Vector2i(1, 0): {"terrain": CombatTileData.TerrainType.PLAIN, "height": 0},
				Vector2i(2, 0): {"terrain": CombatTileData.TerrainType.PLAIN, "height": 0},
			}
		)
	)
	var unit := _make_unit({"action_points": 2})
	var legal_moves := CombatRules.get_legal_moves(unit, board)
	assert_true(Vector2i(1, 0) in legal_moves)
	assert_false(Vector2i(2, 0) in legal_moves)


func test_legal_moves_respect_fatigue_budget() -> void:
	var board := CombatBoard.new()
	(
		board
		. setup_tiles(
			{
				Vector2i(0, 0): {"terrain": CombatTileData.TerrainType.PLAIN, "height": 0},
				Vector2i(1, 0): {"terrain": CombatTileData.TerrainType.SWAMP, "height": 0},
			}
		)
	)
	var unit := _make_unit({"action_points": 9, "fatigue": 93, "max_fatigue": 100})
	assert_false(Vector2i(1, 0) in CombatRules.get_legal_moves(unit, board))


func test_attack_targets_exclude_adjacent_enemy_two_height_levels_away() -> void:
	var board := CombatBoard.new()
	(
		board
		. setup_tiles(
			{
				Vector2i(0, 0): {"terrain": CombatTileData.TerrainType.PLAIN, "height": 0},
				Vector2i(1, 0): {"terrain": CombatTileData.TerrainType.PLAIN, "height": 2},
			}
		)
	)
	board.set_occupied(Vector2i(0, 0), "a")
	board.set_occupied(Vector2i(1, 0), "d")
	var attacker := _make_unit({"id": "a", "position": Vector2i(0, 0)})
	var defender := _make_unit({"id": "d", "team": "enemy", "position": Vector2i(1, 0)})
	assert_eq(CombatRules.get_attack_targets(attacker, board, [attacker, defender]).size(), 0)


func test_high_ground_adds_hit_chance_bonus() -> void:
	var board := CombatBoard.new()
	(
		board
		. setup_tiles(
			{
				Vector2i(0, 0): {"terrain": CombatTileData.TerrainType.PLAIN, "height": 2},
				Vector2i(1, 0): {"terrain": CombatTileData.TerrainType.PLAIN, "height": 0},
			}
		)
	)
	var attacker := _make_unit({"position": Vector2i(0, 0), "melee_skill": 60})
	var defender := _make_unit(
		{"id": "d", "team": "enemy", "position": Vector2i(1, 0), "melee_defense": 20}
	)
	assert_eq(CombatRules.calculate_hit_chance(attacker, defender, board), 50)


func test_low_ground_applies_hit_chance_penalty_per_level() -> void:
	var board := CombatBoard.new()
	(
		board
		. setup_tiles(
			{
				Vector2i(0, 0): {"terrain": CombatTileData.TerrainType.PLAIN, "height": 0},
				Vector2i(1, 0): {"terrain": CombatTileData.TerrainType.PLAIN, "height": 2},
			}
		)
	)
	var attacker := _make_unit({"position": Vector2i(0, 0), "melee_skill": 60})
	var defender := _make_unit(
		{"id": "d", "team": "enemy", "position": Vector2i(1, 0), "melee_defense": 20}
	)
	assert_eq(CombatRules.calculate_hit_chance(attacker, defender, board), 20)
