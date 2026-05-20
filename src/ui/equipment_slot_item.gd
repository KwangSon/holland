class_name EquipmentSlotItem extends PanelContainer

signal item_dropped(slot_type: EquipmentSlot, item: Item)
signal equipment_item_dropped(slot_type: EquipmentSlot, item: Item, from_slot_type: EquipmentSlot)

enum EquipmentSlot { WEAPON, HEAD, BODY, ACCESSORY }

var slot_type: EquipmentSlot = EquipmentSlot.WEAPON
var equipped_item: Item = null

var _vbox: VBoxContainer
var _slot_label: Label
var _icon_rect: TextureRect
var _item_name_label: Label


func _init() -> void:
	# 스타일 설정
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.border_color = Color(0.4, 0.4, 0.5, 0.5)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	add_theme_stylebox_override("panel", style)

	# 레이아웃
	_vbox = VBoxContainer.new()
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_theme_constant_override("separation", 4)
	add_child(_vbox)

	# 슬롯 레이블
	_slot_label = Label.new()
	_slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slot_label.add_theme_font_size_override("font_size", 12)
	_vbox.add_child(_slot_label)

	# 아이콘 영역
	_icon_rect = TextureRect.new()
	_icon_rect.custom_minimum_size = Vector2(48, 48)
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_vbox.add_child(_icon_rect)

	# 아이템 이름
	_item_name_label = Label.new()
	_item_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_item_name_label.add_theme_font_size_override("font_size", 10)
	_vbox.add_child(_item_name_label)

	_update_slot_label()


func _ready() -> void:
	pass


func setup(slot: EquipmentSlot, initial_item: Item = null) -> void:
	slot_type = slot
	equipped_item = initial_item
	_update_slot_label()
	_update_display()


func set_item(item: Item) -> void:
	equipped_item = item
	_update_display()


func clear_item() -> void:
	equipped_item = null
	_update_display()


func _update_slot_label() -> void:
	match slot_type:
		EquipmentSlot.WEAPON:
			_slot_label.text = "무기"
		EquipmentSlot.HEAD:
			_slot_label.text = "머리"
		EquipmentSlot.BODY:
			_slot_label.text = "몸통"
		EquipmentSlot.ACCESSORY:
			_slot_label.text = "액세서리"


func _update_display() -> void:
	if equipped_item != null:
		_icon_rect.texture = equipped_item.icon
		_item_name_label.text = equipped_item.name
	else:
		_icon_rect.texture = null
		_item_name_label.text = "(빈 슬롯)"


# ============================================================
# 드래그 앤 드롭 - 드롭 수신 (인벤토리에서 아이템 드래그)
# ============================================================


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY:
		var drag_data := data as Dictionary
		if drag_data.has("type"):
			# 인벤토리에서 드래그된 아이템
			if drag_data["type"] == "inventory_item":
				return true
			# 다른 장비 슬롯에서 드래그된 아이템 (교환)
			if drag_data["type"] == "equipment_item":
				return true
	return false


func _drop_data(_pos: Vector2, data: Variant) -> void:
	if typeof(data) == TYPE_DICTIONARY:
		var drag_data := data as Dictionary
		if drag_data.has("item") and drag_data["item"] is Item:
			var dropped_item: Item = drag_data["item"]
			# 아이템 타입과 슬롯이 일치하는지 확인
			if _is_item_compatible(dropped_item):
				# 인벤토리에서 드래그된 경우
				if drag_data.get("type") == "inventory_item":
					item_dropped.emit(slot_type, dropped_item)
				# 다른 장비 슬롯에서 드래그된 경우 (교환)
				elif drag_data.get("type") == "equipment_item":
					var from_slot_type: EquipmentSlot = drag_data.get("slot_type", slot_type)
					equipment_item_dropped.emit(slot_type, dropped_item, from_slot_type)


func _is_item_compatible(item: Item) -> bool:
	match slot_type:
		EquipmentSlot.WEAPON:
			return item.type == Item.ItemType.WEAPON
		EquipmentSlot.HEAD:
			return item.type == Item.ItemType.HEAD_ARMOR
		EquipmentSlot.BODY:
			return item.type == Item.ItemType.BODY_ARMOR
		EquipmentSlot.ACCESSORY:
			return item.type == Item.ItemType.ACCESSORY
	return false


# ============================================================
# 드래그 앤 드롭 - 드래그 시작 (장비 해제용)
# ============================================================


func _get_drag_data(_pos: Vector2) -> Variant:
	if equipped_item != null:
		var drag_data := {"type": "equipment_item", "item": equipped_item, "slot_type": slot_type}
		# 드래그 프리뷰 생성
		var preview := TextureRect.new()
		preview.texture = equipped_item.icon
		preview.custom_minimum_size = Vector2(32, 32)
		set_drag_preview(preview)
		return drag_data
	return null


# ============================================================
# 마우스 이벤트 - 더블클릭으로 빠른 장착/해제
# ============================================================


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 더블클릭 감지를 위해선 별도 처리 필요 (단순 클릭은 부모에서 처리)
		pass
