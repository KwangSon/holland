class_name EnemyArchetypeData
extends RefCounted

var id: String = ""
var display_name: String = ""
var family: String = ""
var unit_data: Dictionary = {}
var skill_ids: Array[String] = []


static func create(data: Dictionary):
	var archetype = new()
	archetype.id = data.get("id", "")
	archetype.display_name = data.get("display_name", "")
	archetype.family = data.get("family", "")
	archetype.unit_data = data.get("unit_data", {}).duplicate(true)
	archetype.skill_ids.assign(data.get("skill_ids", []))
	return archetype


func create_unit(unit_id: String, position: Vector2i) -> CombatUnit:
	var data := unit_data.duplicate(true)
	data["id"] = unit_id
	data["display_name"] = display_name
	data["team"] = "enemy"
	data["position"] = position
	data["is_ai"] = true
	return CombatUnit.create(data)
