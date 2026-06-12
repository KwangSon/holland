class_name InjuryData
extends RefCounted

var id: String = ""
var display_name: String = ""
var body_part: String = "body"
var temporary: bool = true
var stat_modifiers: Dictionary = {}
var dot_effect_id: String = ""
var recovery_days_range: Vector2i = Vector2i.ZERO


static func create(data: Dictionary):
	var injury = new()
	injury.id = data.get("id", "")
	injury.display_name = data.get("display_name", "")
	injury.body_part = data.get("body_part", "body")
	injury.temporary = data.get("temporary", true)
	injury.stat_modifiers = data.get("stat_modifiers", {})
	injury.dot_effect_id = data.get("dot_effect_id", "")
	injury.recovery_days_range = data.get("recovery_days_range", Vector2i.ZERO)
	return injury
