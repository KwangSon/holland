class_name ExploreScreen extends Node2D

const MAP_TEXTURE := preload("res://asset/map.jpg")
const MARKER_RADIUS := 10.0
const TWEEN_DURATION := 0.25

var _marker: Node2D
var _marker_pos: Vector2 = Vector2.ZERO
var _tween: Tween = null

var _pause_btn: Button
var _menu_popup: HudMenuPopup


func _ready() -> void:
	_setup_map()
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


func _setup_marker() -> void:
	_marker = Node2D.new()
	_marker.name = "PlayerMarker"
	_marker_pos = get_viewport_rect().size / 2.0
	_marker.position = _marker_pos
	_marker.draw.connect(_on_marker_draw)
	add_child(_marker)


func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	_build_top_bar(canvas)
	_build_menu_popup(canvas)


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

	var menu_btn := Button.new()
	menu_btn.text = "☰"
	menu_btn.pressed.connect(_on_menu_pressed)
	hbox.add_child(menu_btn)


func _build_menu_popup(canvas: CanvasLayer) -> void:
	_menu_popup = HudMenuPopup.new()
	canvas.add_child(_menu_popup)
	_menu_popup.add_item("전투 테스트", _on_combat_pressed)
	_menu_popup.add_item("타이틀로", _on_title_pressed)


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


func _set_marker_position(pos: Vector2) -> void:
	_marker.position = pos
	_marker.queue_redraw()


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


func _on_menu_pressed() -> void:
	_menu_popup.toggle()


func _on_combat_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.COMBAT)


func _on_title_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.TITLE)
