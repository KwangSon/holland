class_name CombatBoard

## Vector2i → unit_id (String) for occupied cells.
var occupied: Dictionary = {}

## Vector2i → true for all valid (non-empty) cells.
var _valid: Dictionary = {}


func setup(valid_cells: Array[Vector2i]) -> void:
	_valid.clear()
	occupied.clear()
	for cell: Vector2i in valid_cells:
		_valid[cell] = true


func is_valid(cell: Vector2i) -> bool:
	return _valid.has(cell)


## A cell is passable if it is valid and not occupied by another unit.
func is_passable(cell: Vector2i) -> bool:
	return _valid.has(cell) and not occupied.has(cell)


## Returns all valid neighboring cells using odd-r offset coordinates
## (pointy-top hexagons, odd rows shifted right — matches Godot's default hex TileMapLayer).
func get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var offsets: Array[Vector2i]
	if cell.y % 2 == 0:
		offsets = [
			Vector2i(-1, -1),
			Vector2i(0, -1),
			Vector2i(-1, 0),
			Vector2i(1, 0),
			Vector2i(-1, 1),
			Vector2i(0, 1),
		]
	else:
		offsets = [
			Vector2i(0, -1),
			Vector2i(1, -1),
			Vector2i(-1, 0),
			Vector2i(1, 0),
			Vector2i(0, 1),
			Vector2i(1, 1),
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


## odd-r offset → cube coordinates. Required for correct hex_distance.
func _to_cube(cell: Vector2i) -> Vector3i:
	var offset: int = (cell.y - (cell.y & 1)) >> 1
	var q: int = cell.x - offset
	var r: int = cell.y
	return Vector3i(q, r, -q - r)
