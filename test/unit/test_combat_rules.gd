extends GutTest


func _make_unit(overrides: Dictionary = {}) -> CombatUnit:
	var defaults := {
		"id": "u1",
		"display_name": "Test",
		"team": "player",
		"position": Vector2i(0, 0),
		"max_hp": 30,
		"max_fatigue": 100,
		"attack_power": 10,
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
	var atk := _make_unit({"attack_power": 15})
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
	var atk := _make_unit({"attack_power": 10})
	var def := _make_unit({"id": "d1", "team": "enemy", "hp": 30, "max_hp": 30})
	var result := CombatRules.roll_attack(atk, def, _make_rng(1))
	CombatRules.apply_attack_result(def, result)
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
