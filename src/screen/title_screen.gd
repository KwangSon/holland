class_name TitleScreen extends Node2D

var _main_container: CenterContainer
var _load_container: CenterContainer


func _ready() -> void:
	_setup_ui()


func initialize(_data: Dictionary) -> void:
	pass


func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	_main_container = _build_main_container()
	canvas.add_child(_main_container)

	_load_container = _build_load_container()
	_load_container.visible = false
	canvas.add_child(_load_container)


func _build_main_container() -> CenterContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title_label := Label.new()
	title_label.text = "holland"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	_add_spacer(vbox, 16)

	_add_button(vbox, "새 캠페인", _on_new_campaign_pressed)
	_add_button(vbox, "캠페인 불러오기", _on_load_campaign_pressed)
	_add_button(vbox, "설정", _on_settings_pressed)
	_add_button(vbox, "튜토리얼 영상", _on_tutorial_pressed)
	_add_button(vbox, "제작진", _on_credits_pressed)
	_add_button(vbox, "종료하기", _on_quit_pressed)

	return center


func _build_load_container() -> CenterContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var header := Label.new()
	header.text = "캠페인 불러오기"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	_add_spacer(vbox, 12)

	for slot: int in SaveManager.MAX_SLOTS:
		var btn := Button.new()
		if SaveManager.has_save(slot):
			btn.text = "슬롯 %d  —  저장됨" % (slot + 1)
		else:
			btn.text = "슬롯 %d  —  (비어 있음)" % (slot + 1)
			btn.disabled = true
		btn.pressed.connect(_on_slot_pressed.bind(slot))
		vbox.add_child(btn)

	_add_spacer(vbox, 12)
	_add_button(vbox, "뒤로", _on_back_pressed)

	return center


func _add_button(parent: VBoxContainer, label: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = label
	btn.pressed.connect(callback)
	parent.add_child(btn)


func _add_spacer(parent: VBoxContainer, height: int) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	parent.add_child(spacer)


# ============================================================
# 메인 메뉴 콜백
# ============================================================


func _on_new_campaign_pressed() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.EXPLORE)


func _on_load_campaign_pressed() -> void:
	_main_container.visible = false
	_load_container.visible = true


func _on_settings_pressed() -> void:
	pass  # TODO


func _on_tutorial_pressed() -> void:
	pass  # TODO


func _on_credits_pressed() -> void:
	pass  # TODO


func _on_quit_pressed() -> void:
	get_tree().quit()


# ============================================================
# 불러오기 패널 콜백
# ============================================================


func _on_slot_pressed(_slot: int) -> void:
	pass  # TODO: SaveManager.load_game(_slot), ScreenManager.change_screen(...)


func _on_back_pressed() -> void:
	_load_container.visible = false
	_main_container.visible = true
