class_name CombatTileData

enum TerrainType { PLAIN, ROUGH, SWAMP, BLOCKED }

const MIN_HEIGHT := 0
const MAX_HEIGHT := 3

var terrain: TerrainType = TerrainType.PLAIN
var height: int = MIN_HEIGHT


func set_terrain(value: int) -> void:
	assert(
		value >= TerrainType.PLAIN and value <= TerrainType.BLOCKED,
		"CombatTileData: invalid terrain type %d" % value
	)
	terrain = value as TerrainType


func set_height(value: int) -> void:
	assert(
		value >= MIN_HEIGHT and value <= MAX_HEIGHT,
		"CombatTileData: height must be between %d and %d" % [MIN_HEIGHT, MAX_HEIGHT]
	)
	height = value


func is_blocked() -> bool:
	return terrain == TerrainType.BLOCKED
