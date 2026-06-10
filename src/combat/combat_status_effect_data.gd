class_name CombatStatusEffectData
extends RefCounted

var id: String = ""
var display_name: String = ""
var duration_turns: int = 1
var blocks_actions: bool = false
var blocks_movement: bool = false
var damage_per_turn: int = 0
var melee_defense_bonus: int = 0
var ranged_defense_bonus: int = 0
var tags: Array[String] = []


static func create(data: Dictionary):
	var status = new()
	status.id = data.get("id", "")
	status.display_name = data.get("display_name", "")
	status.duration_turns = data.get("duration_turns", 1)
	status.blocks_actions = data.get("blocks_actions", false)
	status.blocks_movement = data.get("blocks_movement", false)
	status.damage_per_turn = data.get("damage_per_turn", 0)
	status.melee_defense_bonus = data.get("melee_defense_bonus", 0)
	status.ranged_defense_bonus = data.get("ranged_defense_bonus", 0)
	status.tags.assign(data.get("tags", []))
	return status
