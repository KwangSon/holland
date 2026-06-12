extends GutTest


func _make_unit(overrides: Dictionary = {}) -> CombatUnit:
	var defaults := {
		"id": "u1",
		"display_name": "Test",
		"team": "player",
		"position": Vector2i(0, 0),
		"max_hp": 30,
		"head_armor": 12,
		"body_armor": 20,
		"max_action_points": 9,
		"max_fatigue": 80,
		"morale": 95,
		"resolve": 45,
		"melee_skill": 60,
		"ranged_skill": 35,
		"melee_defense": 8,
		"ranged_defense": 6,
		"damage": 11,
	}
	defaults.merge(overrides, true)
	return CombatUnit.create(defaults)


func test_format_unit_stats_includes_core_combat_resources() -> void:
	var unit := _make_unit()
	unit.hp = 24
	unit.action_points = 5
	unit.fatigue = 17
	unit.head_armor = 8
	unit.body_armor = 13
	unit.adjust_morale_state(-1)

	var text := CombatUi.format_unit_stats(unit)

	assert_string_contains(text, "HP 24/30")
	assert_string_contains(text, "머리갑 8/12")
	assert_string_contains(text, "몸갑 13/20")
	assert_string_contains(text, "AP 5/9")
	assert_string_contains(text, "피로도 17/80")
	assert_string_contains(text, "사기 wavering(95)")
	assert_string_contains(text, "상태 없음")


func test_format_unit_stats_lists_status_effects_with_remaining_turns() -> void:
	var unit := _make_unit()
	unit.apply_status(CombatStatusEffectRegistry.BLEEDING_ID, 3)
	unit.apply_status(CombatStatusEffectRegistry.SHIELDWALL_ID, 1)

	var text := CombatUi.format_unit_stats(unit)

	assert_string_contains(text, "상태 출혈 3턴")
	assert_string_contains(text, "방패벽 1턴")
