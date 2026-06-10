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
var _move_preview_label: Label
var _log_label: Label
var _queue_container: HBoxContainer
var _end_round_btn: Button
var _wait_turn_btn: Button
var _recover_btn: Button
var _end_turn_btn: Button
var _attack_btn: Button
var _attack_mode: bool = false
var _selected_skill_id: String = CombatSkillRegistry.BASIC_ATTACK_ID
var _skill_buttons: Dictionary = {}
var _pause_menu: PauseMenuPopup

var _result_panel: PanelContainer
var _result_label: Label
var _result_btn: Button

# Hover pathfinding
var _hovered_cell: Vector2i = Vector2i(-1, -1)
var _hover_path: Array[Vector2i] = []
var _combat_log := CombatLog.new()


func _ready() -> void:
	_setup_tile_layer()
	_draw_test_map()
	_setup_combat()
	_setup_overlay_layers()
	_setup_ui()
	_setup_camera()
	_start_turn()


func initialize(_data: Dictionary) -> void:
	pass


func _setup_camera() -> void:
	var camera := FreeCamera.new()
	camera.name = "FreeCamera"
	camera.position = Vector2(200, 200)
	camera.zoom = Vector2(2.0, 2.0)
	add_child(camera)


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
	var tile_data_by_cell: Dictionary = {}
	for y: int in TEST_MAP.size():
		var row: Array = TEST_MAP[y]
		for x: int in row.size():
			var tile_index := row[x] as int
			if tile_index != EMPTY_TILE:
				tile_data_by_cell[Vector2i(x, y)] = _get_test_map_tile_data(tile_index)

	var encounter: Dictionary = SaveManager.rna.get("encounter", {})
	_state = CombatState.new()
	_state.start_encounter_tiles(
		_units_from_rna(SaveManager.rna.get("party", [])),
		_units_from_rna(encounter.get("enemies", [])),
		tile_data_by_cell,
		encounter.get("seed", 0)
	)


func _get_test_map_tile_data(tile_index: int) -> Dictionary:
	match tile_index:
		0:
			return {"terrain": CombatTileData.TerrainType.PLAIN, "height": 0}
		1:
			return {"terrain": CombatTileData.TerrainType.ROUGH, "height": 0}
		2:
			return {"terrain": CombatTileData.TerrainType.PLAIN, "height": 1}
		3:
			return {"terrain": CombatTileData.TerrainType.ROUGH, "height": 1}
		4:
			return {"terrain": CombatTileData.TerrainType.SWAMP, "height": 0}
		_:
			return {"terrain": CombatTileData.TerrainType.PLAIN, "height": 0}


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
	_build_pause_menu(canvas)
	_build_result_popup(canvas)
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

	# 도망가기 버튼
	var flee_btn := Button.new()
	flee_btn.text = "도망가기"
	flee_btn.pressed.connect(_on_flee_pressed)
	hbox.add_child(flee_btn)

	# 설정 (X) 버튼
	var settings_btn := Button.new()
	settings_btn.text = "X"
	settings_btn.pressed.connect(_on_settings_pressed)
	hbox.add_child(settings_btn)


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

	_move_preview_label = Label.new()
	info_vbox.add_child(_move_preview_label)

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

	_end_round_btn = CombatUi.add_button(btn_hbox, "라운드 종료", _on_end_round_pressed)
	_wait_turn_btn = CombatUi.add_button(btn_hbox, "대기", _on_wait_turn_pressed)
	_recover_btn = CombatUi.add_button(btn_hbox, "회복", _on_recover_pressed)
	_end_turn_btn = CombatUi.add_button(btn_hbox, "턴 종료", _on_end_turn_pressed)
	_skill_buttons = CombatUi.add_skill_bar(action_vbox, _on_skill_pressed)
	_attack_btn = CombatUi.add_button(action_vbox, "공격", _on_attack_pressed)

	_queue_container = HBoxContainer.new()
	_queue_container.add_theme_constant_override("separation", 8)
	action_vbox.add_child(_queue_container)


func _build_pause_menu(canvas: CanvasLayer) -> void:
	_pause_menu = PauseMenuPopup.new()
	canvas.add_child(_pause_menu)
	(
		_pause_menu
		. setup(
			[
				{"label": "닫기", "callback": _on_close_pressed},
				{"label": "타이틀로", "callback": _on_back_pressed},
				{"label": "종료하기", "callback": _on_quit_pressed},
			]
		)
	)


func _build_result_popup(canvas: CanvasLayer) -> void:
	_result_panel = PanelContainer.new()
	_result_panel.set_anchors_preset(Control.PRESET_CENTER)
	_result_panel.visible = false
	canvas.add_child(_result_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	_result_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(_result_label)

	_result_btn = Button.new()
	_result_btn.text = "확인"
	_result_btn.pressed.connect(_on_result_confirm_pressed)
	vbox.add_child(_result_btn)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_on_mouse_move()
		return

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


func _on_mouse_move() -> void:
	if _phase != InputPhase.UNIT_SELECTED:
		_clear_hover_path()
		_refresh_overlays()
		return

	var active := _state.get_active_unit()
	if active == null:
		_clear_hover_path()
		_refresh_overlays()
		return

	var tile_local := _tile_layer.to_local(get_global_mouse_position())
	var cell := _tile_layer.local_to_map(tile_local)

	if _attack_mode:
		_hovered_cell = cell
		_hover_path = []
		_refresh_attack_preview(cell)
		_refresh_overlays()
		return

	var movement_skill_id := _get_selected_movement_skill_id()
	var legal_moves := _state.get_legal_moves(active.id, movement_skill_id)
	if cell in legal_moves:
		if cell != _hovered_cell:
			_hovered_cell = cell
			_hover_path = _state.get_board().find_path(active.position, cell)
			_refresh_move_preview()
			_refresh_overlays()
	else:
		if _hovered_cell != Vector2i(-1, -1):
			_clear_hover_path()
			_refresh_overlays()


func _handle_cell_click(cell: Vector2i) -> void:
	var active := _state.get_active_unit()
	if active == null:
		return

	match _phase:
		InputPhase.IDLE:
			if _state.get_board().occupied.get(cell, "") == active.id:
				_selected_id = active.id
				_phase = InputPhase.UNIT_SELECTED
				_refresh_overlays()

		InputPhase.UNIT_SELECTED:
			var board := _state.get_board()
			var occupied_id: String = board.occupied.get(cell, "")

			# Attack mode - click on tile to attack enemy on that tile
			if _attack_mode:
				var target_ids := _state.get_attack_targets(active.id, _selected_skill_id)
				if occupied_id != "" and occupied_id in target_ids:
					var result := _state.attack(active.id, occupied_id, _selected_skill_id)
					_log_attack(result, occupied_id)
					_attack_mode = false
					_attack_btn.text = "공격"
					_deselect()
					_check_outcome()
					return
				# Click on empty tile in attack mode - just cancel attack mode
				_attack_mode = false
				_attack_btn.text = "공격"
				_refresh_overlays()
				return

			# Attack?
			if occupied_id != "" and occupied_id in _state.get_attack_targets(active.id, _selected_skill_id):
				var result := _state.attack(active.id, occupied_id, _selected_skill_id)
				_log_attack(result, occupied_id)
				_deselect()
				_check_outcome()
				return

			# Move?
			var movement_skill_id := _get_selected_movement_skill_id()
			if cell in _state.get_legal_moves(active.id, movement_skill_id):
				# Use hover path if available, otherwise find new path
				var move_path: Array[Vector2i] = (
					_hover_path
					if _hover_path.size() > 0 and _hovered_cell == cell
					else _state.get_board().find_path(active.position, cell)
				)
				if move_path.size() > 1:
					_move_unit_along_path(active, move_path)
				else:
					_state.move_unit(active.id, cell, movement_skill_id)
					_log_move_result(active)
				_deselect()
				return

			# Deselect on any other click.
			_deselect()


func _deselect() -> void:
	_selected_id = ""
	_phase = InputPhase.IDLE
	_attack_mode = false
	_attack_btn.text = "공격"
	_clear_hover_path()
	_refresh_overlays()
	_refresh_ui()
	_start_turn()


func _on_highlight_draw() -> void:
	if _state == null or _phase != InputPhase.UNIT_SELECTED:
		return
	var active := _state.get_active_unit()
	if active == null or active.id != _selected_id:
		return

	if _attack_mode:
		var board := _state.get_board()
		var skill: CombatSkillData = CombatSkillRegistry.get_skill(_selected_skill_id)
		for cell: Vector2i in board.get_valid_cells():
			if cell == active.position:
				continue
			if skill.attack_range <= 1 and not board.is_melee_reachable(active.position, cell):
				continue
			if board.hex_distance(active.position, cell) > skill.attack_range:
				continue
			_draw_hex(_highlight_layer, cell, Color(1.0, 0.75, 0.1, 0.22))
		for uid: String in _state.get_attack_targets(_selected_id, _selected_skill_id):
			var unit: CombatUnit = _find_unit(uid)
			if unit != null:
				_draw_hex(_highlight_layer, unit.position, Color(1.0, 0.2, 0.2, 0.8))
		return

	for cell: Vector2i in _state.get_legal_moves(_selected_id, _get_selected_movement_skill_id()):
		_draw_hex(_highlight_layer, cell, Color(0.2, 0.5, 1.0, 0.35))

	for uid: String in _state.get_attack_targets(_selected_id, _selected_skill_id):
		var unit: CombatUnit = _find_unit(uid)
		if unit != null:
			_draw_hex(_highlight_layer, unit.position, Color(1.0, 0.2, 0.2, 0.45))

	# Selected cell — yellow outline
	_draw_hex(_highlight_layer, active.position, Color(1.0, 0.9, 0.0, 0.5))

	# Hover path — green
	for cell: Vector2i in _hover_path:
		_draw_hex(_highlight_layer, cell, Color(0.2, 0.8, 0.2, 0.5))


func _on_unit_draw() -> void:
	if _state == null:
		return
	var active := _state.get_active_unit()
	for unit: CombatUnit in _state.get_all_units():
		if not unit.alive:
			continue
		# Use visual_position for smooth tween animation
		var pos := (
			unit.visual_position
			if unit.visual_position != Vector2.ZERO
			else _cell_to_local(unit.position)
		)
		var color := Color.CORNFLOWER_BLUE if unit.team == "player" else Color.INDIAN_RED
		# Active unit gets a brighter tint.
		if active != null and unit.id == active.id:
			color = color.lightened(0.35)

		# Draw sprite texture if available
		if unit.sprite_texture:
			var sprite_size := Vector2(24, 24)
			var rect := Rect2(pos - sprite_size / 2.0, sprite_size)
			_unit_layer.draw_texture_rect(unit.sprite_texture, rect, false, color)
		else:
			_unit_layer.draw_circle(pos, 12.0, color)

		# HP bar
		var bar_width: float = 24.0
		var bar_height: float = 4.0
		var hp_ratio: float = clamp(float(unit.hp) / float(unit.max_hp), 0.0, 1.0)
		var head_ratio: float = _safe_ratio(unit.head_armor, unit.max_head_armor)
		var body_ratio: float = _safe_ratio(unit.body_armor, unit.max_body_armor)

		# Head armor (steel blue)
		_unit_layer.draw_rect(
			Rect2(pos.x - bar_width / 2.0, pos.y - 26.0, bar_width, bar_height),
			Color(0.18, 0.22, 0.28)
		)
		_unit_layer.draw_rect(
			Rect2(pos.x - bar_width / 2.0, pos.y - 26.0, bar_width * head_ratio, bar_height),
			Color(0.45, 0.65, 0.9)
		)

		# Body armor (gray)
		_unit_layer.draw_rect(
			Rect2(pos.x - bar_width / 2.0, pos.y - 22.0, bar_width, bar_height),
			Color(0.18, 0.22, 0.28)
		)
		_unit_layer.draw_rect(
			Rect2(pos.x - bar_width / 2.0, pos.y - 22.0, bar_width * body_ratio, bar_height),
			Color(0.72, 0.74, 0.78)
		)

		# HP (red)
		_unit_layer.draw_rect(
			Rect2(pos.x - bar_width / 2.0, pos.y - 18.0, bar_width, bar_height),
			Color(0.2, 0.2, 0.2)
		)
		_unit_layer.draw_rect(
			Rect2(pos.x - bar_width / 2.0, pos.y - 18.0, bar_width * hp_ratio, bar_height),
			Color(0.9, 0.2, 0.2)
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


func _refresh_ui() -> void:
	_round_label.text = "라운드 %d" % _state.round_number
	_ally_label.text = "아군 %d" % _count_alive("player")
	_enemy_label.text = "적군 %d" % _count_alive("enemy")

	var active := _state.get_active_unit()
	if active == null:
		_bottom_panel.visible = false
		_move_preview_label.text = ""
		return

	_bottom_panel.visible = true

	var team_queue := _state.get_remaining_team_queue(active.team)
	_rebuild_queue(_state.get_remaining_turn_queue())

	var is_player_turn := active.team == "player"
	var recover_skill: CombatSkillData = CombatSkillRegistry.get_skill(CombatSkillRegistry.RECOVER_ID)
	var recover_cost: int = recover_skill.action_point_cost
	_end_round_btn.disabled = not is_player_turn
	_wait_turn_btn.disabled = not is_player_turn or team_queue.size() <= 1
	_recover_btn.disabled = not is_player_turn or active.action_points < recover_cost
	_end_turn_btn.disabled = not is_player_turn
	_attack_btn.disabled = not is_player_turn or not _get_selected_movement_skill_id().is_empty()
	CombatUi.sync_skill_buttons(_skill_buttons, _selected_skill_id, is_player_turn, active)

	if active.is_ai:
		_unit_name_label.text = active.display_name + " (AI 차례)"
		_unit_stats_label.text = CombatUi.format_unit_stats(active)
		_move_preview_label.text = ""
		return
	_unit_name_label.text = active.display_name
	_unit_stats_label.text = CombatUi.format_unit_stats(active)
	_refresh_move_preview()


func _log_attack(result: Dictionary, defender_id: String) -> void:
	if result.is_empty():
		_append_log("공격 실패")
		return
	var defender := _find_unit(defender_id)
	var name_str := defender.display_name if defender != null else defender_id
	var skill_name: String = result.get("skill_display_name", result.get("skill_id", "공격"))
	if result.get("hit", false):
		var part := "머리" if result.get("body_part", "body") == "head" else "몸"
		var msg := (
			"%s → %s %s  명중 %d%%  굴림 %d  갑옷 %d→%d  HP -%d"
			% [
				skill_name,
				name_str,
				part,
				result.get("hit_chance", 0),
				result.get("roll", 0),
				result.get("armor_before", 0),
				result.get("armor_after", 0),
				result.get("hp_damage", 0),
			]
		)
		if result.get("killed", false):
			msg += "  [사망]"
		_append_log(msg)
	else:
		var msg := (
			"%s → %s  명중 %d%%  굴림 %d  빗나감"
			% [skill_name, name_str, result.get("hit_chance", 0), result.get("roll", 0)]
		)
		_append_log(msg)


func _log_move_result(unit: CombatUnit) -> void:
	var move_result := _state.get_last_move_result()
	var zoc_attacks: Array = move_result.get("zoc_attacks", [])
	if zoc_attacks.is_empty():
		return
	var attack: Dictionary = zoc_attacks[-1]
	var attacker := _find_unit(attack.get("attacker_id", ""))
	var attacker_name: String = (
		attacker.display_name if attacker != null else attack.get("attacker_id", "")
	)
	if move_result.get("blocked_by_zoc", false):
		_append_log(
			"%s 이탈 저지 ← %s  HP %d"
			% [
				unit.display_name,
				attacker_name,
				attack.get("hp_damage", 0),
			]
		)
	else:
		_append_log("%s 이탈 성공  %d회 회피" % [unit.display_name, zoc_attacks.size()])


func _append_log(message: String) -> void:
	_log_label.text = _combat_log.append(message)


func _check_outcome() -> void:
	var outcome := _state.get_outcome()
	if outcome == "ongoing":
		_refresh_overlays()
		_refresh_ui()
		return
	_phase = InputPhase.IDLE
	_refresh_overlays()
	_bottom_panel.visible = false
	_result_label.text = "전투 승리!" if outcome == "victory" else "전투 패배..."
	_result_panel.visible = true


func _on_result_confirm_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.EXPLORE)


func _on_flee_pressed() -> void:
	_phase = InputPhase.IDLE
	_refresh_overlays()
	_bottom_panel.visible = false
	_result_label.text = "도망쳤습니다... (패배)"
	_result_panel.visible = true


func _on_close_pressed() -> void:
	_pause_menu.hide_menu()
	get_tree().paused = false


func _on_settings_pressed() -> void:
	_pause_menu.toggle()
	get_tree().paused = _pause_menu.visible


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_end_round_pressed() -> void:
	_state.end_player_phase()
	_deselect()


func _on_wait_turn_pressed() -> void:
	_state.wait_turn()
	_deselect()


func _on_recover_pressed() -> void:
	var active := _state.get_active_unit()
	if active == null or not _state.recover(active.id):
		return
	_append_log("%s 회복  피로도 %d/%d" % [active.display_name, active.fatigue, active.max_fatigue])
	_deselect()


func _on_skill_pressed(skill_id: String) -> void:
	_selected_skill_id = skill_id
	_refresh_move_preview()
	_refresh_overlays()


func _on_attack_pressed() -> void:
	if _phase != InputPhase.UNIT_SELECTED:
		return
	_attack_mode = not _attack_mode
	_attack_btn.text = "취소" if _attack_mode else "공격"
	if _attack_mode:
		var tile_local := _tile_layer.to_local(get_global_mouse_position())
		_refresh_attack_preview(_tile_layer.local_to_map(tile_local))
	else:
		_clear_hover_path()
	_refresh_overlays()


func _on_end_turn_pressed() -> void:
	_state.end_turn()
	_deselect()


func _on_back_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.TITLE)


func _start_turn() -> void:
	if _state.get_outcome() != "ongoing":
		_check_outcome()
		return

	var active := _state.get_active_unit()
	if active == null:
		return

	if active.is_ai:
		_run_ai_turn(active)
	else:
		# Player turn - auto-select the active unit
		_phase = InputPhase.UNIT_SELECTED
		_selected_id = active.id
		_refresh_overlays()
		_refresh_ui()


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
		var path := _state.get_board().find_path(active.position, best_move)
		if path.size() > 1:
			_move_unit_along_path(active, path)
		else:
			_state.move_unit(active.id, best_move)
			_log_move_result(active)
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


func _safe_ratio(value: int, max_value: int) -> float:
	if max_value <= 0:
		return 0.0
	return clamp(float(value) / float(max_value), 0.0, 1.0)


func _clear_hover_path() -> void:
	_hovered_cell = Vector2i(-1, -1)
	_hover_path = []
	_refresh_move_preview()


func _refresh_attack_preview(cell: Vector2i) -> void:
	if _move_preview_label == null:
		return
	if _state == null or _phase != InputPhase.UNIT_SELECTED or not _attack_mode:
		_move_preview_label.text = ""
		return

	var active := _state.get_active_unit()
	if active == null or active.id != _selected_id:
		_move_preview_label.text = ""
		return

	var board := _state.get_board()
	var defender_id: String = board.occupied.get(cell, "")
	var target_ids := _state.get_attack_targets(active.id, _selected_skill_id)
	if defender_id == "" or not defender_id in target_ids:
		_show_skill_summary(active)
		return

	var defender := _find_unit(defender_id)
	if defender == null:
		_show_skill_summary(active)
		return

	var skill: CombatSkillData = CombatSkillRegistry.get_skill(_selected_skill_id)
	var preview := CombatRules.preview_attack(active, defender, board, skill, _state.get_all_units())
	_move_preview_label.text = (
		"공격 예측  명중 %d%%  몸 갑 %d HP %d  머리 갑 %d HP %d  AP %d  피로도 +%d"
		% [
			preview["hit_chance"],
			preview["body_armor_damage"],
			preview["body_hp_damage"],
			preview["head_armor_damage"],
			preview["head_hp_damage"],
			preview["action_point_cost"],
			preview["fatigue_cost"],
		]
	)


func _refresh_move_preview() -> void:
	if _move_preview_label == null:
		return
	if _state == null or _phase != InputPhase.UNIT_SELECTED:
		_move_preview_label.text = ""
		return

	var active := _state.get_active_unit()
	if active == null or active.id != _selected_id:
		_move_preview_label.text = ""
		return
	if _hover_path.size() < 2:
		_show_skill_summary(active)
		return

	var board := _state.get_board()
	var ap_cost := CombatRules.get_path_ap_cost(_hover_path, active, board)
	var fatigue_cost := CombatRules.get_path_fatigue_cost(_hover_path, active, board)
	var movement_skill_id := _get_selected_movement_skill_id()
	if not movement_skill_id.is_empty():
		var skill: CombatSkillData = CombatSkillRegistry.get_skill(movement_skill_id)
		ap_cost += skill.action_point_cost
		fatigue_cost += skill.fatigue_cost
	_move_preview_label.text = "이동 비용  AP %d  피로도 +%d" % [ap_cost, fatigue_cost]


func _show_skill_summary(active: CombatUnit) -> void:
	var skill: CombatSkillData = CombatSkillRegistry.get_skill(_selected_skill_id)
	var movement_skill_id := _get_selected_movement_skill_id()
	var target_count := 0 if not movement_skill_id.is_empty() else _state.get_attack_targets(
		active.id, _selected_skill_id
	).size()
	_move_preview_label.text = (
		"%s  사거리 %d  대상 %d  AP %d  피로도 +%d"
		% [
			skill.display_name,
			skill.attack_range,
			target_count,
			skill.action_point_cost,
			skill.fatigue_cost,
		]
	)


func _get_selected_movement_skill_id() -> String:
	var skill: CombatSkillData = CombatSkillRegistry.get_skill(_selected_skill_id)
	return _selected_skill_id if "movement" in skill.tags else ""

func _move_unit_along_path(unit: CombatUnit, path: Array[Vector2i]) -> void:
	if path.size() < 2:
		_state.move_unit(unit.id, path[0], _get_selected_movement_skill_id())
		_log_move_result(unit)
		_refresh_overlays()
		_refresh_ui()
		return

	var dest := path[-1]
	var dest_pos := _cell_to_local(dest)
	var moved := _state.move_unit(unit.id, dest, _get_selected_movement_skill_id())
	_log_move_result(unit)
	if not moved:
		unit.visual_position = _cell_to_local(unit.position)
		_refresh_overlays()
		_refresh_ui()
		return

	var start_pos := _cell_to_local(path[0])
	unit.visual_position = start_pos

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)

	tween.tween_property(unit, "visual_position", dest_pos, 0.2 * path.size())
	tween.finished.connect(
		func():
			unit.visual_position = dest_pos
			_refresh_overlays()
			_refresh_ui()
	)
