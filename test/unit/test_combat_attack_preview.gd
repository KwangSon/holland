extends GutTest

const CombatSkillDataScript := preload("res://src/combat/combat_skill_data.gd")


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


func test_preview_attack_reports_hit_chance_costs_and_body_damage() -> void:
	var attacker := _make_unit({"damage": 10, "armor_penetration": 50, "melee_skill": 60})
	var defender := _make_unit(
		{
			"id": "d",
			"team": "enemy",
			"melee_defense": 20,
			"body_armor": 10,
			"head_armor": 4,
		}
	)
	var skill = (
		CombatSkillDataScript
		. create(
			{
				"id": "heavy",
				"action_point_cost": 5,
				"fatigue_cost": 20,
				"damage_percent": 120,
			}
		)
	)

	var preview := CombatRules.preview_attack(attacker, defender, null, skill)

	assert_eq(preview["hit_chance"], 40)
	assert_eq(preview["action_point_cost"], 5)
	assert_eq(preview["fatigue_cost"], 20)
	assert_eq(preview["raw_damage"], 12)
	assert_eq(preview["body_armor_damage"], 10)
	assert_eq(preview["body_hp_damage"], 7)
	assert_eq(preview["head_armor_damage"], 4)
	assert_eq(preview["head_hp_damage"], 15)
