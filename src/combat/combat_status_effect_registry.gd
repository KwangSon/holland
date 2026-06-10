class_name CombatStatusEffectRegistry

const CombatStatusEffectDataScript := preload("res://src/combat/combat_status_effect_data.gd")

const STUNNED_ID: String = "stunned"
const BLEEDING_ID: String = "bleeding"
const NETTED_ID: String = "netted"
const SHIELDWALL_ID: String = "shieldwall"


static func get_status(status_id: String):
	var definitions := _get_definitions()
	assert(definitions.has(status_id), "CombatStatusEffectRegistry: unknown status %s" % status_id)
	return CombatStatusEffectDataScript.create(definitions[status_id])


static func get_all_status_ids() -> Array[String]:
	var result: Array[String] = []
	for status_id: String in _get_definitions().keys():
		result.append(status_id)
	return result


static func blocks_actions(status_ids: Array[String]) -> bool:
	for status_id: String in status_ids:
		if get_status(status_id).blocks_actions:
			return true
	return false


static func blocks_movement(status_ids: Array[String]) -> bool:
	for status_id: String in status_ids:
		if get_status(status_id).blocks_movement:
			return true
	return false


static func get_melee_defense_bonus(status_ids: Array[String]) -> int:
	var bonus := 0
	for status_id: String in status_ids:
		bonus += get_status(status_id).melee_defense_bonus
	return bonus


static func get_ranged_defense_bonus(status_ids: Array[String]) -> int:
	var bonus := 0
	for status_id: String in status_ids:
		bonus += get_status(status_id).ranged_defense_bonus
	return bonus


static func get_start_turn_damage(status_ids: Array[String]) -> int:
	var damage := 0
	for status_id: String in status_ids:
		damage += get_status(status_id).damage_per_turn
	return damage


static func _get_definitions() -> Dictionary:
	return {
		STUNNED_ID:
		{
			"id": STUNNED_ID,
			"display_name": "기절",
			"duration_turns": 1,
			"blocks_actions": true,
			"blocks_movement": true,
			"tags": ["control"],
		},
		BLEEDING_ID:
		{
			"id": BLEEDING_ID,
			"display_name": "출혈",
			"duration_turns": 3,
			"damage_per_turn": 3,
			"tags": ["damage_over_time"],
		},
		NETTED_ID:
		{
			"id": NETTED_ID,
			"display_name": "그물",
			"duration_turns": 2,
			"blocks_movement": true,
			"tags": ["control"],
		},
		SHIELDWALL_ID:
		{
			"id": SHIELDWALL_ID,
			"display_name": "방패벽",
			"duration_turns": 1,
			"melee_defense_bonus": 15,
			"ranged_defense_bonus": 15,
			"tags": ["defense", "shield"],
		},
	}
