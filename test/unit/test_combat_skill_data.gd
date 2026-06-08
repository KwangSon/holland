extends GutTest

const CombatSkillDataScript := preload("res://src/combat/combat_skill_data.gd")


func test_basic_attack_has_expected_costs() -> void:
	var skill = CombatSkillDataScript.basic_attack()
	assert_eq(skill.id, "basic_attack")
	assert_eq(skill.action_point_cost, 4)
	assert_eq(skill.fatigue_cost, 30)
	assert_eq(skill.attack_range, 1)
	assert_true("melee" in skill.tags)


func test_create_assigns_optional_combat_modifiers() -> void:
	var skill = (
		CombatSkillDataScript
		. create(
			{
				"id": "heavy_swing",
				"display_name": "강타",
				"action_point_cost": 6,
				"fatigue_cost": 40,
				"range": 1,
				"hit_modifier": -10,
				"damage_percent": 125,
				"armor_damage_percent": 150,
				"armor_penetration_modifier": 15,
				"head_hit_modifier": 5,
				"fatigue_recovery": 20,
				"tags": ["melee", "heavy"],
			}
		)
	)
	assert_eq(skill.id, "heavy_swing")
	assert_eq(skill.hit_modifier, -10)
	assert_eq(skill.damage_percent, 125)
	assert_eq(skill.armor_damage_percent, 150)
	assert_eq(skill.armor_penetration_modifier, 15)
	assert_eq(skill.head_hit_modifier, 5)
	assert_eq(skill.fatigue_recovery, 20)
	assert_true("heavy" in skill.tags)
