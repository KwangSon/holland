class_name CombatScreen extends Node2D

const TILE_SET := preload("res://asset/new_tile_set.tres")
const SOURCE_ID := 1
const EMPTY_TILE := -1
const MAP_ORIGIN := Vector2(96, 72)

const TEST_MAP := [
	[-1, -1, 2, 2, 2, 2, 2, -1, -1],
	[-1, 2, 0, 0, 1, 0, 0, 2, -1],
	[2, 0, 0, 1, 1, 1, 0, 0, 2],
	[2, 0, 3, 0, 1, 0, 3, 0, 2],
	[2, 0, 0, 0, 4, 0, 0, 0, 2],
	[2, 0, 3, 0, 0, 0, 3, 0, 2],
	[2, 0, 0, 1, 1, 1, 0, 0, 2],
	[-1, 2, 0, 0, 1, 0, 0, 2, -1],
	[-1, -1, 2, 2, 2, 2, 2, -1, -1],
]

var _tile_layer: TileMapLayer


func _ready() -> void:
	_setup_tile_layer()
	_draw_test_map()
	_setup_ui()


func initialize(_data: Dictionary) -> void:
	pass


func _setup_tile_layer() -> void:
	_tile_layer = TileMapLayer.new()
	_tile_layer.name = "CombatTileMapLayer"
	_tile_layer.tile_set = TILE_SET
	_tile_layer.position = MAP_ORIGIN
	add_child(_tile_layer)


func _draw_test_map() -> void:
	for y: int in TEST_MAP.size():
		var row: Array = TEST_MAP[y]
		for x: int in row.size():
			var tile_index: int = row[x]
			if tile_index == EMPTY_TILE:
				continue
			_tile_layer.set_cell(Vector2i(x, y), SOURCE_ID, Vector2i(0, tile_index))


func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	canvas.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Combat Screen - TileMapLayer test"
	vbox.add_child(title)

	var back_button := Button.new()
	back_button.text = "타이틀로"
	back_button.pressed.connect(_on_back_pressed)
	vbox.add_child(back_button)


func _on_back_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.TITLE)
