class_name EncounterData
extends RefCounted

const EnemyRegistryScript := preload("res://src/data/enemy_registry.gd")

var id: String = ""
var display_name: String = ""
var enemy_entries: Array[Dictionary] = []
var encounter_seed: int = 1


static func create(data: Dictionary):
	var encounter = new()
	encounter.id = data.get("id", "")
	encounter.display_name = data.get("display_name", "")
	encounter.enemy_entries.assign(data.get("enemy_entries", []))
	encounter.encounter_seed = data.get("seed", 1)
	return encounter


func create_enemy_units() -> Array[CombatUnit]:
	return EnemyRegistryScript.create_units(enemy_entries)
