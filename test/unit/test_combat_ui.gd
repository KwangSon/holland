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


func test_format_attack_log_includes_hit_roll_body_armor_hp_and_death() -> void:
	var text := CombatUi.format_attack_log(
		{
			"skill_display_name": "철퇴 가격",
			"hit": true,
			"hit_chance": 68,
			"roll": 41,
			"body_part": "head",
			"armor_before": 12,
			"armor_after": 3,
			"hp_damage": 7,
			"killed": true,
		},
		"산적"
	)

	assert_string_contains(text, "철퇴 가격 → 산적 머리")
	assert_string_contains(text, "명중 68%")
	assert_string_contains(text, "굴림 41")
	assert_string_contains(text, "갑옷 12→3")
	assert_string_contains(text, "HP -7")
	assert_string_contains(text, "[사망]")


func test_format_attack_log_includes_miss_roll_and_ammo_cost() -> void:
	var text := CombatUi.format_attack_log(
		{
			"skill_display_name": "사격",
			"hit": false,
			"hit_chance": 32,
			"roll": 77,
			"ammo_cost": 1,
		},
		"좀비"
	)

	assert_string_contains(text, "사격 → 좀비")
	assert_string_contains(text, "명중 32%")
	assert_string_contains(text, "굴림 77")
	assert_string_contains(text, "빗나감")
	assert_string_contains(text, "탄약 -1")


func test_format_morale_check_includes_reason_chance_roll_and_state_change() -> void:
	var text := CombatUi.format_morale_check(
		{
			"reason": "ally_death",
			"chance": 45,
			"roll": 82,
			"passed": false,
			"previous_state": "steady",
			"new_state": "wavering",
		},
		"궁수"
	)

	assert_string_contains(text, "궁수 사기 체크(아군 사망)")
	assert_string_contains(text, "확률 45%")
	assert_string_contains(text, "굴림 82")
	assert_string_contains(text, "저하: steady→wavering")


func test_format_attack_preview_includes_damage_costs_and_ammo() -> void:
	var text := CombatUi.format_attack_preview(
		{
			"hit_chance": 55,
			"body_armor_damage": 8,
			"body_hp_damage": 3,
			"head_armor_damage": 6,
			"head_hp_damage": 9,
			"action_point_cost": 5,
			"fatigue_cost": 20,
			"ammo_cost": 1,
		}
	)

	assert_string_contains(text, "공격 예측")
	assert_string_contains(text, "명중 55%")
	assert_string_contains(text, "몸 갑 8 HP 3")
	assert_string_contains(text, "머리 갑 6 HP 9")
	assert_string_contains(text, "AP 5")
	assert_string_contains(text, "피로도 +20")
	assert_string_contains(text, "탄약 1")


func test_add_skill_bar_labels_attack_utility_and_ranged_skills() -> void:
	var parent := autofree(VBoxContainer.new()) as VBoxContainer
	var buttons := CombatUi.add_skill_bar(parent, _on_test_skill_pressed)

	assert_true(CombatSkillRegistry.BASIC_ATTACK_ID in buttons)
	assert_true(CombatSkillRegistry.SPEAR_THRUST_ID in buttons)
	assert_true(CombatSkillRegistry.MACE_STRIKE_ID in buttons)
	assert_true(CombatSkillRegistry.RANGED_SHOT_ID in buttons)
	assert_true(CombatSkillRegistry.FOOTWORK_ID in buttons)
	assert_true(CombatSkillRegistry.SHIELDWALL_ID in buttons)
	assert_string_contains(buttons[CombatSkillRegistry.BASIC_ATTACK_ID].text, "기본 공격")
	assert_string_contains(buttons[CombatSkillRegistry.SPEAR_THRUST_ID].text, "창 찌르기")
	assert_string_contains(buttons[CombatSkillRegistry.MACE_STRIKE_ID].text, "둔기 타격")
	assert_string_contains(buttons[CombatSkillRegistry.RANGED_SHOT_ID].text, "원거리 사격")
	assert_string_contains(buttons[CombatSkillRegistry.RANGED_SHOT_ID].text, "A1")


func test_sync_skill_buttons_disables_unpayable_ranged_ammo_cost() -> void:
	var parent := autofree(VBoxContainer.new()) as VBoxContainer
	var buttons := CombatUi.add_skill_bar(parent, _on_test_skill_pressed)
	var unit := _make_unit({"ammo": 0, "max_ammo": 0})

	CombatUi.sync_skill_buttons(buttons, CombatSkillRegistry.BASIC_ATTACK_ID, true, unit)

	assert_false(buttons[CombatSkillRegistry.BASIC_ATTACK_ID].disabled)
	assert_true(buttons[CombatSkillRegistry.RANGED_SHOT_ID].disabled)
	assert_true(buttons[CombatSkillRegistry.BASIC_ATTACK_ID].button_pressed)


func _on_test_skill_pressed(_skill_id: String) -> void:
	pass
