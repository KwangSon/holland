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
			)
		)
		button.disabled = not enabled or not can_pay_cost
		button.button_pressed = skill_id == selected_skill_id


static func format_unit_stats(unit: CombatUnit) -> String:
	return (
		"HP %d/%d  머리갑 %d/%d  몸갑 %d/%d  AP %d/%d  피로도 %d/%d\n"
		+ "사기 %d  결의 %d  근공 %d  원공 %d  근방 %d  원방 %d  공격력 %d"
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
		unit.morale,
		unit.resolve,
		unit.melee_skill,
		unit.ranged_skill,
		unit.melee_defense,
		unit.ranged_defense,
		unit.damage,
	]


static func _format_skill_label(skill: CombatSkillData) -> String:
	return "%s AP%d F%d" % [skill.display_name, skill.action_point_cost, skill.fatigue_cost]
