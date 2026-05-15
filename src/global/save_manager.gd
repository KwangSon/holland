## Runtime game state (rna) ↔ JSON save files (dna).
## rna: 플레이 중 모든 시스템이 읽고 쓰는 live Dictionary.
## dna: rna를 JSON으로 직렬화한 파일 (user://saves/slot_n.json).
extends Node2D

signal game_saved(slot: int)
signal game_loaded(slot: int)

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 3

var rna: Dictionary = {}


func save_game(slot: int) -> void:
	assert(slot >= 0 and slot < MAX_SLOTS, "SaveManager: invalid slot %d" % slot)
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	assert(
		file != null,
		"SaveManager: write failed slot=%d err=%d" % [slot, FileAccess.get_open_error()]
	)
	file.store_string(JSON.stringify(rna, "\t"))
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
	var dna = JSON.parse_string(file.get_as_text())
	file.close()
	if dna == null or not dna is Dictionary:
		push_error("SaveManager: slot %d contains invalid JSON" % slot)
		return false
	rna = dna
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


func _slot_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot
