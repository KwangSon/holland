class_name InventoryItem extends PanelContainer

var item: Item = null

var _hbox: HBoxContainer
var _icon_rect: TextureRect
var _name_label: Label


func _init() -> void:
	# 스타일 설정
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.22, 0.85)
	style.border_color = Color(0.35, 0.35, 0.4, 0.5)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	add_theme_stylebox_override("panel", style)

	# 레이아웃
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 8)
	add_child(_hbox)

	# 아이콘
	_icon_rect = TextureRect.new()
	_icon_rect.custom_minimum_size = Vector2(32, 32)
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hbox.add_child(_icon_rect)

	# 이름
	_name_label = Label.new()
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 12)
	_hbox.add_child(_name_label)

	# 마우스 호버 효과
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _ready() -> void:
	pass


func set_item(i: Item) -> void:
	item = i
	_icon_rect.texture = i.icon
	_name_label.text = i.name

	# 타입에 따른 색상 표시
	var type_color := Color.WHITE
	match i.type:
		Item.ItemType.WEAPON:
			type_color = Color(1, 0.6, 0.4)  # 주황색
		Item.ItemType.HEAD_ARMOR:
			type_color = Color(0.4, 0.7, 1)  # 파란색
		Item.ItemType.BODY_ARMOR:
			type_color = Color(0.5, 0.8, 0.5)  # 초록색
		Item.ItemType.ACCESSORY:
			type_color = Color(0.9, 0.6, 0.9)  # 보라색
	_name_label.add_theme_color_override("font_color", type_color)


func _on_mouse_entered() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.22, 0.28, 0.9)
	style.border_color = Color(0.5, 0.5, 0.6, 0.7)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	add_theme_stylebox_override("panel", style)


func _on_mouse_exited() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.22, 0.85)
	style.border_color = Color(0.35, 0.35, 0.4, 0.5)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	add_theme_stylebox_override("panel", style)


# ============================================================
# 드래그 앤 드롭 - 드래그 시작
# ============================================================


func _get_drag_data(_pos: Vector2) -> Variant:
	if item != null:
		var drag_data := {"type": "inventory_item", "item": item}
		# 드래그 프리뷰 생성
		var preview := TextureRect.new()
		preview.texture = item.icon
		preview.custom_minimum_size = Vector2(32, 32)
		set_drag_preview(preview)
		return drag_data
	return null
