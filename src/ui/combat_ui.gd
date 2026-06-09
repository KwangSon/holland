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
	for skill_id: String in CombatSkillRegistry.get_attack_skill_ids():
		var skill: CombatSkillData = CombatSkillRegistry.get_skill(skill_id)
		var button := add_button(row, skill.display_name, callback.bind(skill_id))
		button.toggle_mode = true
		buttons[skill_id] = button
	return buttons


static func sync_skill_buttons(
	buttons: Dictionary, selected_skill_id: String, enabled: bool
) -> void:
	for skill_id: String in buttons:
		var button: Button = buttons[skill_id]
		button.disabled = not enabled
		button.button_pressed = skill_id == selected_skill_id
