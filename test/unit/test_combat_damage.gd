extends GutTest


func _make_unit(overrides: Dictionary = {}) -> CombatUnit:
	var defaults := {
		"id": "u1",
		"display_name": "Test",
		"team": "player",
		"max_hp": 30,
		"hp": 30,
		"damage": 10,
		"melee_skill": 95,
	}
	defaults.merge(overrides, true)
	return CombatUnit.create(defaults)


func _make_rng(rng_seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	return rng


func test_roll_attack_defaults_to_body_hit() -> void:
	var attacker := _make_unit({"damage": 10, "chance_to_hit_head": 0})
	var defender := _make_unit({"id": "d", "team": "enemy"})
	var result := CombatRules.roll_attack(attacker, defender, _make_rng(42))
	assert_true(result["hit"])
	assert_eq(result["body_part"], "body")
	assert_eq(result["hp_damage"], 10)


func test_roll_body_part_can_force_head_hit() -> void:
	var attacker := _make_unit({"chance_to_hit_head": 100})
	assert_eq(CombatRules.roll_body_part(attacker, _make_rng(1)), "head")


func test_body_armor_absorbs_damage_before_hp() -> void:
	var attacker := _make_unit({"damage": 10, "armor_penetration": 0})
	var defender := _make_unit({"id": "d", "team": "enemy", "body_armor": 20})
	var result := CombatRules.roll_damage(attacker, defender, attacker.damage, "body")
	CombatRules.apply_attack_result(defender, {"hit": true}.merged(result))
	assert_eq(defender.body_armor, 10)
	assert_eq(defender.hp, 30)


func test_armor_penetration_deals_reduced_hp_damage_through_armor() -> void:
	var attacker := _make_unit({"damage": 10, "armor_penetration": 50})
	var defender := _make_unit({"id": "d", "team": "enemy", "body_armor": 20})
	var result := CombatRules.roll_damage(attacker, defender, attacker.damage, "body")
	assert_eq(result["armor_damage"], 10)
	assert_eq(result["hp_damage"], 4)


func test_head_hit_uses_head_armor_and_hp_multiplier() -> void:
	var attacker := _make_unit({"damage": 10, "armor_penetration": 100})
	var defender := _make_unit({"id": "d", "team": "enemy", "head_armor": 10, "body_armor": 20})
	var result := CombatRules.roll_damage(attacker, defender, attacker.damage, "head")
	CombatRules.apply_attack_result(defender, {"hit": true}.merged(result))
	assert_eq(defender.head_armor, 0)
	assert_eq(defender.body_armor, 20)
	assert_eq(defender.hp, 15)


func test_miss_does_not_damage_armor() -> void:
	var defender := _make_unit({"id": "d", "team": "enemy", "body_armor": 20})
	CombatRules.apply_attack_result(
		defender, {"hit": false, "body_part": "body", "armor_damage": 10, "hp_damage": 10}
	)
	assert_eq(defender.body_armor, 20)
	assert_eq(defender.hp, 30)
