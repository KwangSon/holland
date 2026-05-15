extends GutTest


func _make_board(cells: Array[Vector2i]) -> CombatBoard:
	var board := CombatBoard.new()
	board.setup(cells)
	return board


func _full_board() -> CombatBoard:
	var cells: Array[Vector2i] = []
	for y: int in 5:
		for x: int in 9:
			cells.append(Vector2i(x, y))
	return _make_board(cells)


# ----------------------------------------------------------
# is_valid / is_passable
# ----------------------------------------------------------


func test_valid_cell_is_valid() -> void:
	var board := _make_board([Vector2i(3, 2)])
	assert_true(board.is_valid(Vector2i(3, 2)))


func test_unknown_cell_is_not_valid() -> void:
	var board := _make_board([Vector2i(3, 2)])
	assert_false(board.is_valid(Vector2i(0, 0)))


func test_occupied_cell_is_not_passable() -> void:
	var board := _make_board([Vector2i(3, 2)])
	board.set_occupied(Vector2i(3, 2), "u1")
	assert_false(board.is_passable(Vector2i(3, 2)))


func test_clear_occupied_restores_passable() -> void:
	var board := _make_board([Vector2i(3, 2)])
	board.set_occupied(Vector2i(3, 2), "u1")
	board.clear_occupied(Vector2i(3, 2))
	assert_true(board.is_passable(Vector2i(3, 2)))


# ----------------------------------------------------------
# get_neighbors — even row
# ----------------------------------------------------------


func test_even_row_has_six_neighbors_in_full_grid() -> void:
	var board := _full_board()
	var neighbors := board.get_neighbors(Vector2i(4, 2))
	assert_eq(neighbors.size(), 6)


func test_even_row_neighbors_correct() -> void:
	var board := _full_board()
	var neighbors := board.get_neighbors(Vector2i(4, 2))
	# even row offsets: (-1,-1),(0,-1),(-1,0),(1,0),(-1,1),(0,1)
	var expected: Array[Vector2i] = [
		Vector2i(3, 1),
		Vector2i(4, 1),
		Vector2i(3, 2),
		Vector2i(5, 2),
		Vector2i(3, 3),
		Vector2i(4, 3),
	]
	for cell: Vector2i in expected:
		assert_true(cell in neighbors, "expected neighbor %s missing" % cell)


# ----------------------------------------------------------
# get_neighbors — odd row
# ----------------------------------------------------------


func test_odd_row_neighbors_correct() -> void:
	var board := _full_board()
	var neighbors := board.get_neighbors(Vector2i(4, 1))
	# odd row offsets: (0,-1),(1,-1),(-1,0),(1,0),(0,1),(1,1)
	var expected: Array[Vector2i] = [
		Vector2i(4, 0),
		Vector2i(5, 0),
		Vector2i(3, 1),
		Vector2i(5, 1),
		Vector2i(4, 2),
		Vector2i(5, 2),
	]
	for cell: Vector2i in expected:
		assert_true(cell in neighbors, "expected neighbor %s missing" % cell)


# ----------------------------------------------------------
# hex_distance
# ----------------------------------------------------------


func test_same_cell_distance_zero() -> void:
	var board := _full_board()
	assert_eq(board.hex_distance(Vector2i(3, 2), Vector2i(3, 2)), 0)


func test_adjacent_cell_distance_one() -> void:
	var board := _full_board()
	# (4,2) and (5,2) are in the same even row → horizontal neighbors
	assert_eq(board.hex_distance(Vector2i(4, 2), Vector2i(5, 2)), 1)


func test_adjacent_diagonal_distance_one() -> void:
	var board := _full_board()
	# (4,2) even row, neighbor (4,1) via offset (0,-1)
	assert_eq(board.hex_distance(Vector2i(4, 2), Vector2i(4, 1)), 1)


func test_two_step_distance() -> void:
	var board := _full_board()
	assert_eq(board.hex_distance(Vector2i(4, 2), Vector2i(6, 2)), 2)


# ----------------------------------------------------------
# get_reachable (BFS)
# ----------------------------------------------------------


func test_reachable_excludes_origin() -> void:
	var board := _full_board()
	var reachable := board.get_reachable(Vector2i(4, 2), 2)
	assert_false(Vector2i(4, 2) in reachable)


func test_reachable_range_zero_is_empty() -> void:
	var board := _full_board()
	assert_eq(board.get_reachable(Vector2i(4, 2), 0).size(), 0)


func test_reachable_range_one_has_six_cells_in_open_grid() -> void:
	var board := _full_board()
	assert_eq(board.get_reachable(Vector2i(4, 2), 1).size(), 6)


func test_occupied_cell_blocks_movement() -> void:
	var board := _full_board()
	# Block the only path from (4,2) by occupying all neighbors except (5,2).
	board.set_occupied(Vector2i(3, 1), "x")
	board.set_occupied(Vector2i(4, 1), "x")
	board.set_occupied(Vector2i(3, 2), "x")
	board.set_occupied(Vector2i(3, 3), "x")
	board.set_occupied(Vector2i(4, 3), "x")
	var reachable := board.get_reachable(Vector2i(4, 2), 1)
	assert_eq(reachable.size(), 1)
	assert_true(Vector2i(5, 2) in reachable)
