## Runtime game state (rna) ↔ JSON save files (dna).
## rna is the live Dictionary used by all systems during play.
## Saving serialises rna → user://saves/slot_n.json (dna).
## Loading deserialises dna → rna, then systems read from it.
extends Node2D

signal game_saved(slot: int)
signal game_loaded(slot: int)

const SAVE_DIR := "user://saves/"
const FORMAT_VERSION := 1
const MAX_SLOTS := 3

var rna: Dictionary = {}


func _ready() -> void:
	rna = _default_rna()


func save_game(slot: int) -> void:
	assert(slot >= 0 and slot < MAX_SLOTS, "SaveManager: invalid slot %d" % slot)
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var dna := _build_dna()
	var json_text := JSON.stringify(dna, "\t")
	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	assert(
		file != null,
		"SaveManager: write failed slot=%d err=%d" % [slot, FileAccess.get_open_error()]
	)
	file.store_string(json_text)
	file.close()
	game_saved.emit(slot)


func load_game(slot: int) -> bool:
	assert(slot >= 0 and slot < MAX_SLOTS, "SaveManager: invalid slot %d" % slot)
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	assert(
		file != null,
		"SaveManager: read failed slot=%d err=%d" % [slot, FileAccess.get_open_error()]
	)
	var json_text := file.get_as_text()
	file.close()
	var dna = JSON.parse_string(json_text)
	if dna == null or not dna is Dictionary:
		push_error("SaveManager: slot %d contains invalid JSON" % slot)
		return false
	_parse_dna(dna)
	game_loaded.emit(slot)
	return true


func has_save(slot: int) -> bool:
	assert(slot >= 0 and slot < MAX_SLOTS, "SaveManager: invalid slot %d" % slot)
	return FileAccess.file_exists(_slot_path(slot))


func delete_save(slot: int) -> void:
	assert(slot >= 0 and slot < MAX_SLOTS, "SaveManager: invalid slot %d" % slot)
	var path := _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


## Returns lightweight metadata for title-screen slot preview.
## Returns empty dict if no save exists.
func get_save_info(slot: int) -> Dictionary:
	assert(slot >= 0 and slot < MAX_SLOTS, "SaveManager: invalid slot %d" % slot)
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var dna = JSON.parse_string(file.get_as_text())
	file.close()
	if dna == null or not dna is Dictionary:
		return {}
	return {
		"timestamp": dna.get("timestamp", ""),
		"map_id": (dna.get("world", {}) as Dictionary).get("current_map_id", ""),
	}


func _default_rna() -> Dictionary:
	return {
		"player":
		{
			"cell": Vector2i(0, 0),
			"gold": 0,
		},
		"world":
		{
			"current_map_id": "",
		},
		"flags": {},
		"inventory":
		[
			{"item_id": "monk_staff", "quantity": 1},
			{"item_id": "jade_pendant", "quantity": 1},
		],
		"party":
		[
			CharacterRegistry.default_party_entry("sanzang"),
		],
		# "encounter"는 전투 직전에만 설정
	}


## Converts rna to a JSON-serialisable Dictionary.
## Vector2i → {"x": n, "y": n} because JSON has no native vector type.
func _build_dna() -> Dictionary:
	var player: Dictionary = rna.get("player", {})
	var cell: Vector2i = player.get("cell", Vector2i.ZERO)
	var party_raw: Array = rna.get("party", [])
	var party_dna: Array = []
	for entry: Dictionary in party_raw:
		(
			party_dna
			. append(
				{
					"id": entry.get("id", ""),
					"level": entry.get("level", 1),
					"exp": entry.get("exp", 0),
					"hp": entry.get("hp", 0),
					"max_hp": entry.get("max_hp", 0),
					"mp": entry.get("mp", 0),
					"max_mp": entry.get("max_mp", 0),
					"sg": entry.get("sg", 0),
					"max_sg": entry.get("max_sg", 0),
					"attack": entry.get("attack", 0),
					"defense": entry.get("defense", 0),
					"speed": entry.get("speed", 0),
					"move_range": entry.get("move_range", 0),
					"equipment":
					entry.get("equipment", {"weapon": "", "armor": "", "accessory": ""}),
				}
			)
		)
	return {
		"format_version": FORMAT_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"player":
		{
			"cell_x": cell.x,
			"cell_y": cell.y,
			"gold": player.get("gold", 0),
		},
		"world":
		{
			"current_map_id": (rna.get("world", {}) as Dictionary).get("current_map_id", ""),
		},
		"flags": rna.get("flags", {}),
		"inventory": rna.get("inventory", []),
		"party": party_dna,
	}


## Deserialises dna back into rna, running migrations for older formats.
func _parse_dna(dna: Dictionary) -> void:
	var version: int = dna.get("format_version", 0)
	if version < 1:
		_migrate_v0_to_v1(dna)
	var player: Dictionary = dna.get("player", {})
	var party_dna: Array = dna.get("party", [])
	var party_rna: Array = []
	for entry in party_dna:
		if entry is Dictionary:
			(
				party_rna
				. append(
					{
						"id": entry.get("id", ""),
						"level": entry.get("level", 1),
						"exp": entry.get("exp", 0),
						"hp": entry.get("hp", 0),
						"max_hp": entry.get("max_hp", 0),
						"mp": entry.get("mp", 0),
						"max_mp": entry.get("max_mp", 0),
						"sg": entry.get("sg", 0),
						"max_sg": entry.get("max_sg", 0),
						"attack": entry.get("attack", 0),
						"defense": entry.get("defense", 0),
						"speed": entry.get("speed", 0),
						"move_range": entry.get("move_range", 0),
						"equipment":
						entry.get("equipment", {"weapon": "", "armor": "", "accessory": ""}),
					}
				)
			)
	if party_rna.is_empty():
		party_rna = [CharacterRegistry.default_party_entry("sanzang")]
	rna = {
		"player":
		{
			"cell": Vector2i(player.get("cell_x", 0), player.get("cell_y", 0)),
			"gold": player.get("gold", 0),
		},
		"world":
		{
			"current_map_id": (dna.get("world", {}) as Dictionary).get("current_map_id", ""),
		},
		"flags": dna.get("flags", {}),
		"inventory": dna.get("inventory", []),
		"party": party_rna,
	}


func _migrate_v0_to_v1(dna: Dictionary) -> void:
	dna["format_version"] = 1


func _slot_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot
