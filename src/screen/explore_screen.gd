class_name ExploreScreen extends Node2D

const MAP_TEXTURE := preload("res://asset/map.jpg")
const MARKER_RADIUS := 10.0
const TWEEN_DURATION := 0.25
const ZONE_RADIUS := 80.0

## 마을/POI 정의 — {name, position, encounter}
const VILLAGE_ZONES: Array[Dictionary] = [
	{
		"name": "성채",
		"position": Vector2(490, 420),
		"encounter":
		{
			"enemies":
			[
				{
					"id": "e1",
					"display_name": "도적",
					"team": "enemy",
					"position": Vector2i(7, 3),
					"max_hp": 30,
					"max_fatigue": 90,
					"attack_power": 10,
					"is_ai": true,
				},
				{
					"id": "e2",
					"display_name": "중갑병",
					"team": "enemy",
					"position": Vector2i(6, 4),
					"max_hp": 55,
					"max_fatigue": 110,
					"attack_power": 14,
					"is_ai": true,
				},
			],
			"seed": 42,
		},
	},
	{
		"name": "폐허",
		"position": Vector2(850, 140),
		"encounter":
		{
			"enemies":
			[
				{
					"id": "e1",
					"display_name": "해골 전사",
					"team": "enemy",
					"position": Vector2i(7, 3),
					"max_hp": 25,
					"max_fatigue": 80,
					"attack_power": 12,
					"is_ai": true,
				},
				{
					"id": "e2",
					"display_name": "해골 궁수",
					"team": "enemy",
					"position": Vector2i(7, 5),
					"max_hp": 20,
					"max_fatigue": 70,
					"attack_power": 15,
					"is_ai": true,
				},
				{
					"id": "e3",
					"display_name": "네크로맨서",
					"team": "enemy",
					"position": Vector2i(6, 4),
					"max_hp": 35,
					"max_fatigue": 100,
					"attack_power": 18,
					"is_ai": true,
				},
			],
			"seed": 99,
		},
	},
]

var _marker: Node2D
var _marker_area: Area2D
var _marker_pos: Vector2 = Vector2.ZERO
var _tween: Tween = null
var _zone_layer: Node2D

var _pause_btn: Button
var _pause_menu: PauseMenuPopup


func _ready() -> void:
	_setup_map()
	_setup_zones()
	_setup_marker()
	_setup_ui()
	_setup_camera()


func initialize(_data: Dictionary) -> void:
	pass


# ============================================================
# 초기화
# ============================================================


func _setup_camera() -> void:
	var camera := FreeCamera.new()
	camera.name = "FreeCamera"
	camera.position = get_viewport_rect().size / 2.0
	add_child(camera)


func _setup_map() -> void:
	var sprite := Sprite2D.new()
	sprite.name = "MapSprite"
	sprite.texture = MAP_TEXTURE
	var vp := get_viewport_rect().size
	sprite.position = vp / 2.0
	add_child(sprite)


func _setup_zones() -> void:
	_zone_layer = Node2D.new()
	_zone_layer.name = "ZoneLayer"
	add_child(_zone_layer)
	for data: Dictionary in VILLAGE_ZONES:
		var zone := VillageZone.create_zone(
			data["name"],
			data["position"],
			ZONE_RADIUS,
			data["encounter"],
		)
		zone.marker_entered.connect(_on_zone_entered)
		_zone_layer.add_child(zone)


func _setup_marker() -> void:
	_marker = Node2D.new()
	_marker.name = "PlayerMarker"
	_marker_pos = get_viewport_rect().size / 2.0
	_marker.position = _marker_pos
	_marker.draw.connect(_on_marker_draw)
	add_child(_marker)

	# Area2D - 충돌 감지 (자식 노드)
	_marker_area = Area2D.new()
	_marker_area.name = "MarkerArea"
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape"
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = MARKER_RADIUS
	collision_shape.shape = circle_shape
	_marker_area.add_child(collision_shape)
	_marker.add_child(_marker_area)


func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	_build_top_bar(canvas)
	_build_pause_menu(canvas)


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

	_pause_btn = Button.new()
	_pause_btn.text = "⏸"
	_pause_btn.pressed.connect(_on_pause_pressed)
	hbox.add_child(_pause_btn)

	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right_spacer)

	# 설정 (X) 버튼
	var settings_btn := Button.new()
	settings_btn.text = "X"
	settings_btn.pressed.connect(_on_settings_pressed)
	hbox.add_child(settings_btn)


func _build_pause_menu(canvas: CanvasLayer) -> void:
	_pause_menu = PauseMenuPopup.new()
	canvas.add_child(_pause_menu)
	_pause_menu.setup([
		{"label": "타이틀로", "callback": _on_title_pressed},
		{"label": "종료하기", "callback": _on_quit_pressed},
	])


# ============================================================
# 입력
# ============================================================


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	_move_marker(get_global_mouse_position())


func _move_marker(target: Vector2) -> void:
	_marker_pos = target
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_marker_position, _marker.position, target, TWEEN_DURATION)
	_tween.finished.connect(_on_marker_arrived)


func _set_marker_position(pos: Vector2) -> void:
	_marker.position = pos
	_marker.queue_redraw()


func _on_marker_arrived() -> void:
	pass  # 이제 area_entered 시그널로 자동 감지하므로 불필요 (Tween 완료 알림용)


func _on_zone_entered(zone: VillageZone) -> void:
	_enter_combat(zone)


func _enter_combat(zone: VillageZone) -> void:
	# 커서를 기본으로 복원
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	# 인카운터 데이터 설정
	SaveManager.rna["encounter"] = zone.encounter_data
	if not SaveManager.rna.has("party"):
		# 기본 파티 — 파티가 아직 없으면 테스트용 기본값 사용
		SaveManager.rna["party"] = [
			{
				"id": "p1",
				"display_name": "기사",
				"team": "player",
				"position": Vector2i(1, 3),
				"max_hp": 60,
				"max_fatigue": 120,
				"attack_power": 15,
			},
			{
				"id": "p2",
				"display_name": "궁수",
				"team": "player",
				"position": Vector2i(2, 4),
				"max_hp": 30,
				"max_fatigue": 80,
				"attack_power": 12,
				"is_ai": true,
			},
		]
	ScreenManager.change_screen(ScreenManager.Screen.COMBAT)


# ============================================================
# 렌더링
# ============================================================


func _on_marker_draw() -> void:
	_marker.draw_circle(Vector2.ZERO, MARKER_RADIUS, Color.YELLOW)
	_marker.draw_circle(Vector2.ZERO, MARKER_RADIUS - 3.0, Color(0.2, 0.2, 0.8))


# ============================================================
# 버튼 콜백
# ============================================================


func _on_pause_pressed() -> void:
	get_tree().paused = not get_tree().paused
	_pause_btn.text = "▶" if get_tree().paused else "⏸"


func _on_settings_pressed() -> void:
	_pause_menu.toggle()
	get_tree().paused = _pause_menu.visible


func _on_combat_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.COMBAT)


func _on_title_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.TITLE)


func _on_quit_pressed() -> void:
	get_tree().quit()
