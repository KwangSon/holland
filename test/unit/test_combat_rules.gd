extends GutTest


func _make_unit(overrides: Dictionary = {}) -> CombatUnit:
	var defaults := {
		"id": "u1",
		"display_name": "Test",
		"team": "player",
		"position": Vector2i(0, 0),
		"max_hp": 30,
		"armor": 5,
		"max_ap": 2,
		"initiative": 5,
		"melee_skill": 60,
		"melee_defense": 10,
		"damage_min": 5,
		"damage_max": 10,
		"move_range": 3,
	}
	defaults.merge(overrides, true)
	return CombatUnit.create(defaults)


func _make_rng(rng_seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	return rng


# ----------------------------------------------------------
# calc_hit_chance
# ----------------------------------------------------------


func test_hit_chance_basic() -> void:
	var atk := _make_unit({"melee_skill": 60})
	var def := _make_unit({"melee_defense": 10})
	assert_eq(CombatRules.calc_hit_chance(atk, def), 95)  # 60 - 10 + 50 = 100 → clamped 95


func test_hit_chance_clamp_max() -> void:
	var atk := _make_unit({"melee_skill": 90})
	var def := _make_unit({"melee_defense": 5})
	assert_eq(CombatRules.calc_hit_chance(atk, def), 95)


func test_hit_chance_clamp_min() -> void:
	var atk := _make_unit({"melee_skill": 10})
	var def := _make_unit({"melee_defense": 80})
	assert_eq(CombatRules.calc_hit_chance(atk, def), 5)


func test_hit_chance_exact_50() -> void:
	var atk := _make_unit({"melee_skill": 50})
	var def := _make_unit({"melee_defense": 50})
	assert_eq(CombatRules.calc_hit_chance(atk, def), 50)


# ----------------------------------------------------------
# roll_attack — determinism
# ----------------------------------------------------------


func test_roll_attack_deterministic_with_same_seed() -> void:
	var atk := _make_unit()
	var def1 := _make_unit({"id": "d1", "team": "enemy"})
	var def2 := _make_unit({"id": "d2", "team": "enemy"})
	var result1 := CombatRules.roll_attack(atk, def1, _make_rng(42))
	var result2 := CombatRules.roll_attack(atk, def2, _make_rng(42))
	assert_eq(result1["hit"], result2["hit"])
	assert_eq(result1["roll"], result2["roll"])
	assert_eq(result1["hp_damage"], result2["hp_damage"])


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
	var atk := _make_unit({"melee_skill": 99})  # near certain hit
	var def := _make_unit({"id": "d1", "team": "enemy", "armor": 0, "hp": 30, "max_hp": 30})
	var result := CombatRules.roll_attack(atk, def, _make_rng(1))
	CombatRules.apply_attack_result(def, result)
	if result["hit"]:
		assert_lt(def.hp, 30)
	else:
		assert_eq(def.hp, 30)


func test_apply_hit_reduces_armor_first() -> void:
	var def := _make_unit({"id": "d1", "team": "enemy", "armor": 100, "hp": 30, "max_hp": 30})
	var result := {"hit": true, "hp_damage": 0, "armor_absorbed": 8}
	CombatRules.apply_attack_result(def, result)
	assert_eq(def.hp, 30)
	assert_eq(def.armor, 92)


func test_apply_lethal_hit_marks_dead() -> void:
	var def := _make_unit({"id": "d1", "team": "enemy", "armor": 0, "hp": 5, "max_hp": 30})
	var result := {"hit": true, "hp_damage": 10, "armor_absorbed": 0}
	CombatRules.apply_attack_result(def, result)
	assert_eq(def.hp, 0)
	assert_false(def.alive)


func test_apply_miss_does_nothing() -> void:
	var def := _make_unit({"id": "d1", "team": "enemy", "armor": 5, "hp": 30, "max_hp": 30})
	var result := {"hit": false, "hp_damage": 0, "armor_absorbed": 0}
	CombatRules.apply_attack_result(def, result)
	assert_eq(def.hp, 30)
	assert_eq(def.armor, 5)


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
