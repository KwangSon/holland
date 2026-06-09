class_name CombatBoard

const CombatTileDataScript := preload("res://src/combat/combat_tile_data.gd")

const HEIGHT_CHANGE_AP_COST := 1
const HEIGHT_CHANGE_FATIGUE_COST := 5

## Vector2i → unit_id (String) for occupied cells.
var occupied: Dictionary = {}

## Vector2i → true for all valid (non-empty) cells.
var _valid: Dictionary = {}

## Vector2i → CombatTileData.
var _tiles: Dictionary = {}

## AStar2D for pathfinding
var _astar: AStar2D = null


func setup(valid_cells: Array[Vector2i]) -> void:
	_valid.clear()
	_tiles.clear()
	occupied.clear()
	for cell: Vector2i in valid_cells:
		_valid[cell] = true
		_tiles[cell] = CombatTileDataScript.new()
	_build_astar(valid_cells)


func setup_tiles(tile_data_by_cell: Dictionary) -> void:
	_valid.clear()
	_tiles.clear()
	occupied.clear()
	for cell: Vector2i in tile_data_by_cell.keys():
		var tile_data = tile_data_by_cell[cell]
		var tile = _create_tile_data(tile_data)
		_valid[cell] = true
		_tiles[cell] = tile
	_build_astar(_valid.keys())


func is_valid(cell: Vector2i) -> bool:
	return _valid.has(cell)


func get_valid_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in _valid.keys():
		result.append(cell)
	return result


## A cell is passable if it is valid and not occupied by another unit.
func is_passable(cell: Vector2i) -> bool:
	return _valid.has(cell) and not occupied.has(cell) and not get_tile_data(cell).is_blocked()


func get_tile_data(cell: Vector2i):
	assert(is_valid(cell), "CombatBoard: invalid cell %s" % cell)
	return _tiles[cell]


func get_height(cell: Vector2i) -> int:
	return get_tile_data(cell).height


func set_height(cell: Vector2i, height: int) -> void:
	get_tile_data(cell).set_height(height)


func get_terrain(cell: Vector2i) -> int:
	return get_tile_data(cell).terrain


func set_terrain(cell: Vector2i, terrain: int) -> void:
	get_tile_data(cell).set_terrain(terrain)
	_build_astar(_valid.keys())


func get_step_ap_cost(from: Vector2i, to: Vector2i, unit: CombatUnit = null) -> int:
	assert(is_valid(from), "CombatBoard: invalid from cell %s" % from)
	assert(is_valid(to), "CombatBoard: invalid to cell %s" % to)
	assert(to in get_neighbors(from), "CombatBoard: cells must be adjacent")
	var cost := _get_terrain_ap_cost(get_terrain(to))
	if get_height(from) != get_height(to) and not _has_pathfinder(unit):
		cost += HEIGHT_CHANGE_AP_COST
	return cost


func get_step_fatigue_cost(from: Vector2i, to: Vector2i, _unit: CombatUnit = null) -> int:
	assert(is_valid(from), "CombatBoard: invalid from cell %s" % from)
	assert(is_valid(to), "CombatBoard: invalid to cell %s" % to)
	assert(to in get_neighbors(from), "CombatBoard: cells must be adjacent")
	var cost := _get_terrain_fatigue_cost(get_terrain(to))
	if get_height(from) != get_height(to):
		cost += HEIGHT_CHANGE_FATIGUE_COST
	return cost


func is_melee_reachable(attacker_cell: Vector2i, defender_cell: Vector2i) -> bool:
	if not is_valid(attacker_cell) or not is_valid(defender_cell):
		return false
	if not defender_cell in get_neighbors(attacker_cell):
		return false
	return abs(get_height(attacker_cell) - get_height(defender_cell)) <= 1


## Returns all valid neighboring cells using flat-top offset coordinates
## Offsets are uniform regardless of column parity (matches actual screen behavior)
func get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var offsets: Array[Vector2i] = [
		Vector2i(-1, -1),  # 정북 (N)
		Vector2i(0, -1),  # 북동 (NE)
		Vector2i(1, 0),  # 남동 (SE)
		Vector2i(1, 1),  # 정남 (S)
		Vector2i(0, 1),  # 남서 (SW)
		Vector2i(-1, 0),  # 북서 (NW)
	]
	var result: Array[Vector2i] = []
	for offset: Vector2i in offsets:
		var neighbor := cell + offset
		if is_valid(neighbor):
			result.append(neighbor)
	return result


## Cube-coordinate hex distance for odd-r offset cells.
func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var ac := _to_cube(a)
	var bc := _to_cube(b)
	return (abs(ac.x - bc.x) + abs(ac.y - bc.y) + abs(ac.z - bc.z)) / 2


## BFS: returns all passable cells reachable from origin within move_range steps.
## The origin cell is excluded from the result.
func get_reachable(origin: Vector2i, move_range: int) -> Array[Vector2i]:
	var cost: Dictionary = {}  # Vector2i → int
	cost[origin] = 0
	var frontier: Array[Vector2i] = [origin]

	while not frontier.is_empty():
		var next: Array[Vector2i] = []
		for cell: Vector2i in frontier:
			var dist: int = cost[cell]
			if dist >= move_range:
				continue
			for neighbor: Vector2i in get_neighbors(cell):
				if not cost.has(neighbor) and is_passable(neighbor):
					cost[neighbor] = dist + 1
					next.append(neighbor)
		frontier = next

	var result: Array[Vector2i] = []
	for cell: Vector2i in cost.keys():
		if cell != origin:
			result.append(cell)
	return result


func set_occupied(cell: Vector2i, unit_id: String) -> void:
	occupied[cell] = unit_id


func clear_occupied(cell: Vector2i) -> void:
	occupied.erase(cell)


func _create_tile_data(data):
	if data is CombatTileDataScript:
		return data

	var tile = CombatTileDataScript.new()
	tile.set_terrain(data.get("terrain", CombatTileDataScript.TerrainType.PLAIN))
	tile.set_height(data.get("height", CombatTileDataScript.MIN_HEIGHT))
	return tile


func _get_terrain_ap_cost(terrain: int) -> int:
	match terrain:
		CombatTileDataScript.TerrainType.PLAIN:
			return 2
		CombatTileDataScript.TerrainType.ROUGH:
			return 3
		CombatTileDataScript.TerrainType.SWAMP:
			return 4
		_:
			return 999999


func _get_terrain_fatigue_cost(terrain: int) -> int:
	match terrain:
		CombatTileDataScript.TerrainType.PLAIN:
			return 4
		CombatTileDataScript.TerrainType.ROUGH:
			return 6
		CombatTileDataScript.TerrainType.SWAMP:
			return 8
		_:
			return 999999


func _has_pathfinder(unit: CombatUnit) -> bool:
	return unit != null and unit.has_trait("pathfinder")


func _to_cube(cell: Vector2i) -> Vector3i:
	# odd-q vertical layout: q = x, r = y - floor(x/2), s = -q - r
	var q := cell.x
	var r := cell.y - (cell.x >> 1)
	var s := -q - r
	return Vector3i(q, s, r)


## Build AStar2D graph for pathfinding
func _build_astar(valid_cells: Array) -> void:
	_astar = AStar2D.new()

	# Add all unblocked cells as points.
	for cell: Vector2i in valid_cells:
		if get_tile_data(cell).is_blocked():
			continue
		var id := _cell_to_id(cell)
		_astar.add_point(id, Vector2(cell.x, cell.y))

	# Connect adjacent cells (bidirectional)
	for cell: Vector2i in valid_cells:
		var id := _cell_to_id(cell)
		if not _astar.has_point(id):
			continue
		for neighbor: Vector2i in get_neighbors(cell):
			var neighbor_id := _cell_to_id(neighbor)
			if _astar.has_point(neighbor_id) and not _astar.are_points_connected(id, neighbor_id):
				_astar.connect_points(id, neighbor_id, true)


## Convert cell to unique ID for AStar2D
func _cell_to_id(cell: Vector2i) -> int:
	return cell.x * 10000 + cell.y


## Convert ID back to cell
func _id_to_cell(id: int) -> Vector2i:
	@warning_ignore("integer_division")
	var x := id / 10000
	var y := id % 10000
	return Vector2i(x, y)


## Find path from start to end using AStar2D
## Returns array of cells (including start and end)
## Avoids occupied cells by temporarily removing them from AStar
func find_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	if _astar == null:
		return []
	if not is_valid(start) or not is_valid(end):
		return []
	if not is_passable(end):
		return []

	var start_id := _cell_to_id(start)
	var end_id := _cell_to_id(end)

	# Temporarily remove occupied cells from AStar (except start position)
	var occupied_data: Array[Dictionary] = []
	for cell: Vector2i in occupied.keys():
		var id := _cell_to_id(cell)
		if id != start_id and _astar.has_point(id):
			# Store connections before removing
			var connections := _astar.get_point_connections(id)
			occupied_data.append({"id": id, "cell": cell, "connections": connections})
			_astar.remove_point(id)

	# Check if end was occupied (and thus removed)
	if not _astar.has_point(end_id):
		# Restore and return empty path
		for data: Dictionary in occupied_data:
			_astar.add_point(data.id, Vector2(data.cell.x, data.cell.y))
			for conn_id: int in data.connections:
				if _astar.has_point(conn_id):
					_astar.connect_points(data.id, conn_id, true)
		return []

	var path_ids := _astar.get_id_path(start_id, end_id)

	# Restore occupied cells and connections
	for data: Dictionary in occupied_data:
		_astar.add_point(data.id, Vector2(data.cell.x, data.cell.y))
		for conn_id: int in data.connections:
			if _astar.has_point(conn_id):
				_astar.connect_points(data.id, conn_id, true)

	var path: Array[Vector2i] = []
	for id: int in path_ids:
		path.append(_id_to_cell(id))
	return path


## Update AStar2D when occupancy changes
func update_astar_for_occupancy() -> void:
	if _astar == null:
		return

	# Disconnect occupied cells
	for cell: Vector2i in occupied.keys():
		var id := _cell_to_id(cell)
		if _astar.has_point(id):
			# Get connected points
			var connected := _astar.get_point_connections(id)
			for conn_id: int in connected:
				_astar.disconnect_points(id, conn_id)
