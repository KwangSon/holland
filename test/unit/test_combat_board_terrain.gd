extends GutTest

const CombatTileDataScript := preload("res://src/combat/combat_tile_data.gd")


func _make_tile_board(tile_data_by_cell: Dictionary) -> CombatBoard:
	var board := CombatBoard.new()
	board.setup_tiles(tile_data_by_cell)
	return board


func test_plain_same_height_step_costs_base_ap() -> void:
	var board := CombatBoard.new()
	board.setup([Vector2i(3, 2), Vector2i(4, 2)])
	assert_eq(board.get_step_ap_cost(Vector2i(3, 2), Vector2i(4, 2)), 2)


func test_rough_and_swamp_step_costs_use_terrain_ap() -> void:
	var board := _make_tile_board(
		{
			Vector2i(3, 2): {"terrain": CombatTileDataScript.TerrainType.PLAIN, "height": 0},
			Vector2i(4, 2): {"terrain": CombatTileDataScript.TerrainType.ROUGH, "height": 0},
			Vector2i(4, 3): {"terrain": CombatTileDataScript.TerrainType.SWAMP, "height": 0},
		}
	)
	assert_eq(board.get_step_ap_cost(Vector2i(3, 2), Vector2i(4, 2)), 3)
	assert_eq(board.get_step_ap_cost(Vector2i(4, 2), Vector2i(4, 3)), 4)


func test_height_change_adds_ap_and_fatigue_cost() -> void:
	var board := _make_tile_board(
		{
			Vector2i(3, 2): {"terrain": CombatTileDataScript.TerrainType.PLAIN, "height": 0},
			Vector2i(4, 2): {"terrain": CombatTileDataScript.TerrainType.PLAIN, "height": 1},
		}
	)
	assert_eq(board.get_step_ap_cost(Vector2i(3, 2), Vector2i(4, 2)), 3)
	assert_eq(board.get_step_fatigue_cost(Vector2i(3, 2), Vector2i(4, 2)), 9)


func test_pathfinder_trait_removes_height_ap_extra_cost() -> void:
	var board := _make_tile_board(
		{
			Vector2i(3, 2): {"terrain": CombatTileDataScript.TerrainType.PLAIN, "height": 0},
			Vector2i(4, 2): {"terrain": CombatTileDataScript.TerrainType.PLAIN, "height": 1},
		}
	)
	var unit := CombatUnit.create({"id": "u1", "trait_ids": ["pathfinder"]})
	assert_eq(board.get_step_ap_cost(Vector2i(3, 2), Vector2i(4, 2), unit), 2)


func test_height_delta_one_is_melee_reachable() -> void:
	var board := _make_tile_board(
		{
			Vector2i(3, 2): {"terrain": CombatTileDataScript.TerrainType.PLAIN, "height": 0},
			Vector2i(4, 2): {"terrain": CombatTileDataScript.TerrainType.PLAIN, "height": 1},
		}
	)
	assert_true(board.is_melee_reachable(Vector2i(3, 2), Vector2i(4, 2)))


func test_height_delta_two_is_not_melee_reachable() -> void:
	var board := _make_tile_board(
		{
			Vector2i(3, 2): {"terrain": CombatTileDataScript.TerrainType.PLAIN, "height": 0},
			Vector2i(4, 2): {"terrain": CombatTileDataScript.TerrainType.PLAIN, "height": 2},
		}
	)
	assert_false(board.is_melee_reachable(Vector2i(3, 2), Vector2i(4, 2)))
