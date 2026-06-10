class_name CombatUi extends RefCounted


static func add_button(parent: Container, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


static func add_skill_bar(parent: Container, callback: Callable) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var buttons: Dictionary = {}
	var skill_ids := CombatSkillRegistry.get_attack_skill_ids()
	skill_ids.append(CombatSkillRegistry.FOOTWORK_ID)
	for skill_id: String in skill_ids:
		var skill: CombatSkillData = CombatSkillRegistry.get_skill(skill_id)
		var button := add_button(row, _format_skill_label(skill), callback.bind(skill_id))
		button.toggle_mode = true
		buttons[skill_id] = button
	return buttons


static func sync_skill_buttons(
	buttons: Dictionary, selected_skill_id: String, enabled: bool, active_unit: CombatUnit = null
) -> void:
	for skill_id: String in buttons:
		var button: Button = buttons[skill_id]
		var skill: CombatSkillData = CombatSkillRegistry.get_skill(skill_id)
		var can_pay_cost := (
			active_unit == null
			or (
				active_unit.action_points >= skill.action_point_cost
				and active_unit.fatigue + skill.fatigue_cost <= active_unit.max_fatigue
				and active_unit.ammo >= skill.ammo_cost
			)
		)
		button.disabled = not enabled or not can_pay_cost
		button.button_pressed = skill_id == selected_skill_id


static func format_unit_stats(unit: CombatUnit) -> String:
	return (
		"HP %d/%d  머리갑 %d/%d  몸갑 %d/%d  AP %d/%d  피로도 %d/%d\n"
		+ "탄약 %d/%d  사기 %d  결의 %d  근공 %d  원공 %d  근방 %d  원방 %d  공격력 %d"
	) % [
		unit.hp,
		unit.max_hp,
		unit.head_armor,
		unit.max_head_armor,
		unit.body_armor,
		unit.max_body_armor,
		unit.action_points,
		unit.max_action_points,
		unit.fatigue,
		unit.max_fatigue,
		unit.ammo,
		unit.max_ammo,
		unit.morale,
		unit.resolve,
		unit.melee_skill,
		unit.ranged_skill,
		unit.melee_defense,
		unit.ranged_defense,
		unit.damage,
	]


static func format_attack_log(result: Dictionary, defender_name: String) -> String:
	var skill_name: String = result.get("skill_display_name", result.get("skill_id", "공격"))
	var ammo_text := ""
	if result.get("ammo_cost", 0) > 0:
		ammo_text = "  탄약 -%d" % result.get("ammo_cost", 0)
	if not result.get("hit", false):
		return (
			"%s → %s  명중 %d%%  굴림 %d  빗나감%s"
			% [skill_name, defender_name, result.get("hit_chance", 0), result.get("roll", 0), ammo_text]
		)
	var part := "머리" if result.get("body_part", "body") == "head" else "몸"
	var text := (
		"%s → %s %s  명중 %d%%  굴림 %d  갑옷 %d→%d  HP -%d%s"
		% [
			skill_name,
			defender_name,
			part,
			result.get("hit_chance", 0),
			result.get("roll", 0),
			result.get("armor_before", 0),
			result.get("armor_after", 0),
			result.get("hp_damage", 0),
			ammo_text,
		]
	)
	if result.get("killed", false):
		text += "  [사망]"
	return text


static func format_attack_preview(preview: Dictionary) -> String:
	var ammo_text := ""
	if preview["ammo_cost"] > 0:
		ammo_text = "  탄약 %d" % preview["ammo_cost"]
	return (
		"공격 예측  명중 %d%%  몸 갑 %d HP %d  머리 갑 %d HP %d  AP %d  피로도 +%d%s"
		% [
			preview["hit_chance"],
			preview["body_armor_damage"],
			preview["body_hp_damage"],
			preview["head_armor_damage"],
			preview["head_hp_damage"],
			preview["action_point_cost"],
			preview["fatigue_cost"],
			ammo_text,
		]
	)


static func format_skill_summary(skill: CombatSkillData, target_count: int) -> String:
	var ammo_text := ""
	if skill.ammo_cost > 0:
		ammo_text = "  탄약 %d" % skill.ammo_cost
	return (
		"%s  사거리 %d  대상 %d  AP %d  피로도 +%d%s"
		% [
			skill.display_name,
			skill.attack_range,
			target_count,
			skill.action_point_cost,
			skill.fatigue_cost,
			ammo_text,
		]
	)


static func _format_skill_label(skill: CombatSkillData) -> String:
	var label := "%s AP%d F%d" % [skill.display_name, skill.action_point_cost, skill.fatigue_cost]
	if skill.ammo_cost > 0:
		label += " A%d" % skill.ammo_cost
	return label
