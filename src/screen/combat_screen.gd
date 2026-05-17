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

var _round_label: Label
var _ally_label: Label
var _enemy_label: Label
var _bottom_panel: MarginContainer
var _unit_name_label: Label
var _unit_stats_label: Label
var _log_label: Label
var _queue_container: HBoxContainer
var _end_round_btn: Button
var _wait_turn_btn: Button
var _end_turn_btn: Button
var _menu_popup: HudMenuPopup


func _ready() -> void:
	_setup_tile_layer()
	_draw_test_map()
	_setup_combat()
	_setup_overlay_layers()
	_setup_ui()
	_start_turn()


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
	_build_top_bar(canvas)
	_build_bottom_panel(canvas)
	_build_menu_popup(canvas)
	_refresh_ui()


func _build_top_bar(canvas: CanvasLayer) -> void:
	var bar := MarginContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.add_theme_constant_override("margin_top", 8)
	bar.add_theme_constant_override("margin_left", 12)
	bar.add_theme_constant_override("margin_right", 12)
	canvas.add_child(bar)

	var hbox := HBoxContainer.new()
	bar.add_child(hbox)

	var left_spacer := Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left_spacer)

	var center_hbox := HBoxContainer.new()
	center_hbox.add_theme_constant_override("separation", 16)
	hbox.add_child(center_hbox)

	_round_label = Label.new()
	center_hbox.add_child(_round_label)

	_ally_label = Label.new()
	center_hbox.add_child(_ally_label)

	_enemy_label = Label.new()
	center_hbox.add_child(_enemy_label)

	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right_spacer)

	var menu_btn := Button.new()
	menu_btn.text = "☰"
	menu_btn.pressed.connect(_on_menu_pressed)
	hbox.add_child(menu_btn)


func _build_bottom_panel(canvas: CanvasLayer) -> void:
	_bottom_panel = MarginContainer.new()
	_bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bottom_panel.add_theme_constant_override("margin_left", 12)
	_bottom_panel.add_theme_constant_override("margin_right", 12)
	_bottom_panel.add_theme_constant_override("margin_bottom", 12)
	canvas.add_child(_bottom_panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	_bottom_panel.add_child(hbox)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)

	_unit_name_label = Label.new()
	info_vbox.add_child(_unit_name_label)

	_unit_stats_label = Label.new()
	info_vbox.add_child(_unit_stats_label)

	_log_label = Label.new()
	info_vbox.add_child(_log_label)

	var sep := VSeparator.new()
	hbox.add_child(sep)

	var action_vbox := VBoxContainer.new()
	action_vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(action_vbox)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 6)
	action_vbox.add_child(btn_hbox)

	_end_round_btn = Button.new()
	_end_round_btn.text = "라운드 종료"
	_end_round_btn.pressed.connect(_on_end_round_pressed)
	btn_hbox.add_child(_end_round_btn)

	_wait_turn_btn = Button.new()
	_wait_turn_btn.text = "대기"
	_wait_turn_btn.pressed.connect(_on_wait_turn_pressed)
	btn_hbox.add_child(_wait_turn_btn)

	_end_turn_btn = Button.new()
	_end_turn_btn.text = "턴 종료"
	_end_turn_btn.pressed.connect(_on_end_turn_pressed)
	btn_hbox.add_child(_end_turn_btn)

	_queue_container = HBoxContainer.new()
	_queue_container.add_theme_constant_override("separation", 8)
	action_vbox.add_child(_queue_container)


func _build_menu_popup(canvas: CanvasLayer) -> void:
	_menu_popup = HudMenuPopup.new()
	canvas.add_child(_menu_popup)
	_menu_popup.add_item("타이틀로", _on_back_pressed)


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
	_start_turn()


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
	_round_label.text = "라운드 %d" % _state.round_number
	_ally_label.text = "아군 %d" % _count_alive("player")
	_enemy_label.text = "적군 %d" % _count_alive("enemy")

	var active := _state.get_active_unit()
	if active == null:
		_bottom_panel.visible = false
		return

	_bottom_panel.visible = true

	var team_queue := _state.get_remaining_team_queue(active.team)
	_rebuild_queue(team_queue)

	var is_player_turn := active.team == "player"
	_end_round_btn.disabled = not is_player_turn
	_wait_turn_btn.disabled = not is_player_turn or team_queue.size() <= 1
	_end_turn_btn.disabled = not is_player_turn

	if active.is_ai:
		_unit_name_label.text = active.display_name + " (AI 차례)"
		_unit_stats_label.text = ""
		return

	_unit_name_label.text = active.display_name
	_unit_stats_label.text = (
		"HP %d/%d  피로도 %d/%d  공격력 %d"
		% [
			active.hp,
			active.max_hp,
			active.fatigue,
			active.max_fatigue,
			active.attack_power,
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
		_log_label.text = "공격 → %s  빗나감" % [name_str]


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
	_bottom_panel.visible = true
	_unit_name_label.text = "승리!" if outcome == "victory" else "패배..."
	_unit_stats_label.text = ""
	get_tree().create_timer(2.0).timeout.connect(_on_back_pressed)


func _on_menu_pressed() -> void:
	_menu_popup.toggle()


func _on_end_round_pressed() -> void:
	_state.end_player_phase()
	_deselect()


func _on_wait_turn_pressed() -> void:
	_state.wait_turn()
	_deselect()


func _on_end_turn_pressed() -> void:
	_state.end_turn()
	_deselect()


func _on_back_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.TITLE)


# ============================================================
# 헬퍼
# ============================================================


func _start_turn() -> void:
	if _state.get_outcome() != "ongoing":
		_check_outcome()
		return
		
	var active := _state.get_active_unit()
	if active == null:
		return
		
	if active.is_ai:
		_run_ai_turn(active)


func _run_ai_turn(active: CombatUnit) -> void:
	_phase = InputPhase.IDLE
	_selected_id = active.id
	_refresh_overlays()
	_refresh_ui()
	
	# 대기시간으로 AI 턴임을 알림
	await get_tree().create_timer(0.5).timeout
	
	if _state.get_outcome() != "ongoing" or not active.alive:
		return
		
	var all_units := _state.get_all_units()
	var enemies: Array[CombatUnit] = []
	for u in all_units:
		if u.alive and u.team != active.team:
			enemies.append(u)
			
	if enemies.is_empty():
		_state.end_turn()
		_deselect()
		return
		
	var board := _state.get_board()
	var closest_enemy: CombatUnit = null
	var min_dist := 999999
	for e in enemies:
		var dist: int = board.hex_distance(active.position, e.position)
		if dist < min_dist:
			min_dist = dist
			closest_enemy = e
			
	if closest_enemy == null:
		_state.end_turn()
		_deselect()
		return
		
	# 이동 가능한 칸 중 적과 가장 가까운 곳 선택
	var legal_moves := _state.get_legal_moves(active.id)
	var best_move := active.position
	var best_dist: int = board.hex_distance(active.position, closest_enemy.position)
	
	for cell in legal_moves:
		var dist: int = board.hex_distance(cell, closest_enemy.position)
		if dist < best_dist:
			best_dist = dist
			best_move = cell
			
	if best_move != active.position:
		_state.move_unit(active.id, best_move)
		_refresh_overlays()
		_refresh_ui()
		await get_tree().create_timer(0.5).timeout
		
	if _state.get_outcome() != "ongoing" or not active.alive:
		return
		
	# 공격
	var targets := _state.get_attack_targets(active.id)
	if targets.has(closest_enemy.id):
		var result := _state.attack(active.id, closest_enemy.id)
		_log_attack(result, closest_enemy.id)
		_refresh_overlays()
		_refresh_ui()
		await get_tree().create_timer(0.5).timeout
	elif targets.size() > 0:
		var result := _state.attack(active.id, targets[0])
		_log_attack(result, targets[0])
		_refresh_overlays()
		_refresh_ui()
		await get_tree().create_timer(0.5).timeout
		
	_check_outcome()
	if _state.get_outcome() == "ongoing":
		_state.end_turn()
		_deselect()


func _rebuild_queue(queue: Array[CombatUnit]) -> void:
	for child: Node in _queue_container.get_children():
		_queue_container.remove_child(child)
		child.queue_free()
	for i: int in queue.size():
		var lbl := Label.new()
		lbl.text = ("▶ " if i == 0 else "") + queue[i].display_name
		_queue_container.add_child(lbl)


func _count_alive(team: String) -> int:
	var n: int = 0
	for unit: CombatUnit in _state.get_all_units():
		if unit.alive and unit.team == team:
			n += 1
	return n


func _find_unit(uid: String) -> CombatUnit:
	for unit: CombatUnit in _state.get_all_units():
		if unit.id == uid:
			return unit
	return null
