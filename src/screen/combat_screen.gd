class_name CombatScreen extends Node2D

enum InputPhase { IDLE, UNIT_SELECTED }

const TILE_SET := preload("res://asset/hex_tile.tres")
const SOURCE_ID := 0
const EMPTY_TILE := -1
const MAP_ORIGIN := Vector2(96, 72)
## Drawing radius for hex highlights (between tile inradius 12 and circumradius 16).
const HEX_RADIUS := 14.0

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
var _highlight_layer: Node2D
var _unit_layer: Node2D
var _state: CombatState
var _phase: InputPhase = InputPhase.IDLE
var _selected_id: String = ""

var _turn_label: Label
var _log_label: Label


func _ready() -> void:
	_setup_tile_layer()
	_draw_test_map()
	_setup_combat()
	_setup_overlay_layers()
	_setup_ui()


func initialize(_data: Dictionary) -> void:
	pass


# ============================================================
# 초기화
# ============================================================


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


func _setup_combat() -> void:
	var valid_cells: Array[Vector2i] = []
	for y: int in TEST_MAP.size():
		var row: Array = TEST_MAP[y]
		for x: int in row.size():
			if (row[x] as int) != EMPTY_TILE:
				valid_cells.append(Vector2i(x, y))

	var encounter: Dictionary = SaveManager.rna.get("encounter", {})
	_state = CombatState.new()
	_state.start_encounter(
		_units_from_rna(SaveManager.rna.get("party", [])),
		_units_from_rna(encounter.get("enemies", [])),
		valid_cells,
		encounter.get("seed", 0)
	)


func _units_from_rna(entries: Array) -> Array[CombatUnit]:
	var result: Array[CombatUnit] = []
	for entry: Dictionary in entries:
		result.append(CombatUnit.create(entry))
	return result


## Overlay layers are added AFTER the tile layer so they draw on top.
func _setup_overlay_layers() -> void:
	_highlight_layer = Node2D.new()
	_highlight_layer.name = "HighlightLayer"
	_highlight_layer.draw.connect(_on_highlight_draw)
	add_child(_highlight_layer)

	_unit_layer = Node2D.new()
	_unit_layer.name = "UnitLayer"
	_unit_layer.draw.connect(_on_unit_draw)
	add_child(_unit_layer)


func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var top := MarginContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top.add_theme_constant_override("margin_left", 12)
	top.add_theme_constant_override("margin_top", 12)
	canvas.add_child(top)

	var top_vbox := VBoxContainer.new()
	top_vbox.add_theme_constant_override("separation", 4)
	top.add_child(top_vbox)

	_turn_label = Label.new()
	top_vbox.add_child(_turn_label)

	_log_label = Label.new()
	top_vbox.add_child(_log_label)

	var bottom := MarginContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bottom.add_theme_constant_override("margin_left", 12)
	bottom.add_theme_constant_override("margin_bottom", 12)
	canvas.add_child(bottom)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	bottom.add_child(hbox)

	var end_turn_btn := Button.new()
	end_turn_btn.text = "턴 종료"
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	hbox.add_child(end_turn_btn)

	var back_btn := Button.new()
	back_btn.text = "타이틀로"
	back_btn.pressed.connect(_on_back_pressed)
	hbox.add_child(back_btn)

	_refresh_ui()


# ============================================================
# 입력
# ============================================================


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return

	var tile_local := _tile_layer.to_local(get_global_mouse_position())
	var cell := _tile_layer.local_to_map(tile_local)

	if not _state.get_board().is_valid(cell):
		_deselect()
		return

	_handle_cell_click(cell)


func _handle_cell_click(cell: Vector2i) -> void:
	var active := _state.get_active_unit()
	if active == null:
		return

	match _phase:
		InputPhase.IDLE:
			# Select only the active unit's cell.
			if _state.get_board().occupied.get(cell, "") == active.id:
				_selected_id = active.id
				_phase = InputPhase.UNIT_SELECTED
				_refresh_overlays()

		InputPhase.UNIT_SELECTED:
			var board := _state.get_board()
			var occupied_id: String = board.occupied.get(cell, "")

			# Attack?
			if occupied_id != "" and occupied_id in _state.get_attack_targets(active.id):
				var result := _state.attack(active.id, occupied_id)
				_log_attack(result, occupied_id)
				_deselect()
				_check_outcome()
				return

			# Move?
			if cell in _state.get_legal_moves(active.id):
				_state.move_unit(active.id, cell)
				_deselect()
				return

			# Deselect on any other click.
			_deselect()


func _deselect() -> void:
	_selected_id = ""
	_phase = InputPhase.IDLE
	_refresh_overlays()
	_refresh_ui()


# ============================================================
# 렌더링
# ============================================================


func _on_highlight_draw() -> void:
	if _state == null or _phase != InputPhase.UNIT_SELECTED:
		return
	var active := _state.get_active_unit()
	if active == null or active.id != _selected_id:
		return

	# Movement range — blue
	for cell: Vector2i in _state.get_legal_moves(_selected_id):
		_draw_hex(_highlight_layer, cell, Color(0.2, 0.5, 1.0, 0.35))

	# Attackable enemies — red
	for uid: String in _state.get_attack_targets(_selected_id):
		var unit: CombatUnit = _find_unit(uid)
		if unit != null:
			_draw_hex(_highlight_layer, unit.position, Color(1.0, 0.2, 0.2, 0.45))

	# Selected cell — yellow outline
	_draw_hex(_highlight_layer, active.position, Color(1.0, 0.9, 0.0, 0.5))


func _on_unit_draw() -> void:
	if _state == null:
		return
	var active := _state.get_active_unit()
	for unit: CombatUnit in _state.get_all_units():
		if not unit.alive:
			continue
		var pos := _cell_to_local(unit.position)
		var color := Color.CORNFLOWER_BLUE if unit.team == "player" else Color.INDIAN_RED
		# Active unit gets a brighter tint.
		if active != null and unit.id == active.id:
			color = color.lightened(0.35)
		_unit_layer.draw_circle(pos, 12.0, color)
		# HP text
		var hp_text := "%d" % unit.hp
		_unit_layer.draw_string(
			ThemeDB.fallback_font,
			pos + Vector2(-6, 5),
			hp_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			11,
			Color.WHITE
		)


func _draw_hex(layer: Node2D, cell: Vector2i, color: Color) -> void:
	var center := _cell_to_local(cell)
	var pts := PackedVector2Array()
	for i: int in 6:
		var angle := deg_to_rad(60.0 * i)
		pts.append(center + Vector2(HEX_RADIUS * cos(angle), HEX_RADIUS * sin(angle)))
	layer.draw_polygon(pts, PackedColorArray([color]))


func _cell_to_local(cell: Vector2i) -> Vector2:
	return MAP_ORIGIN + _tile_layer.map_to_local(cell)


func _refresh_overlays() -> void:
	_highlight_layer.queue_redraw()
	_unit_layer.queue_redraw()


# ============================================================
# UI
# ============================================================


func _refresh_ui() -> void:
	if _turn_label == null:
		return
	var active := _state.get_active_unit()
	if active == null:
		_turn_label.text = "전투 종료"
		return
	var team_str := "아군" if active.team == "player" else "적군"
	_turn_label.text = (
		"[%s] %s  HP %d/%d  AP %d/%d"
		% [
			team_str,
			active.display_name,
			active.hp,
			active.max_hp,
			active.ap,
			active.max_ap,
		]
	)


func _log_attack(result: Dictionary, defender_id: String) -> void:
	var defender := _find_unit(defender_id)
	var name_str := defender.display_name if defender != null else defender_id
	if result.get("hit", false):
		var msg := "공격 → %s  피해 %d" % [name_str, result.get("hp_damage", 0)]
		if result.get("killed", false):
			msg += "  [사망]"
		_log_label.text = msg
	else:
		_log_label.text = "공격 → %s  빗맘 (굴림 %d)" % [name_str, result.get("roll", 0)]


# ============================================================
# 결과 확인 & 버튼 콜백
# ============================================================


func _check_outcome() -> void:
	var outcome := _state.get_outcome()
	if outcome == "ongoing":
		_refresh_overlays()
		_refresh_ui()
		return
	_refresh_overlays()
	if outcome == "victory":
		_turn_label.text = "승리!"
	else:
		_turn_label.text = "패배..."
	get_tree().create_timer(2.0).timeout.connect(_on_back_pressed)


func _on_end_turn_pressed() -> void:
	_state.end_turn()
	_deselect()


func _on_back_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.TITLE)


# ============================================================
# 헬퍼
# ============================================================


func _find_unit(uid: String) -> CombatUnit:
	for unit: CombatUnit in _state.get_all_units():
		if unit.id == uid:
			return unit
	return null
