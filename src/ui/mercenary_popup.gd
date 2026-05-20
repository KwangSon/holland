class_name MercenaryPopup extends PanelContainer

var _close_btn: Button
var _main_hbox: HBoxContainer

# 좌측: 용병 리스트
var _unit_list_scroll: ScrollContainer
var _unit_list: VBoxContainer

# 중앙: 장비 슬롯
var _equipment_panel: VBoxContainer
var _equipment_slots: Dictionary = {}  # slot_type -> EquipmentSlotItem

# 우측: 인벤토리
var _inventory_scroll: ScrollContainer
var _inventory_grid: GridContainer

# 데이터
var _party: Array[CombatUnit] = []
var _inventory: Array[Item] = []
var _selected_unit: CombatUnit = null
var _unit_cards: Array[UnitCard] = []


func _init() -> void:
	# 전체 배경 스타일
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.12, 0.16, 0.98)
	add_theme_stylebox_override("panel", panel_style)

	# 메인 컨테이너
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)

	# 상단 바 (닫기 버튼 포함)
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 8)
	main_vbox.add_child(top_bar)

	# 제목 (중앙 정렬을 위한 spacer)
	var title_spacer := Control.new()
	title_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title_spacer)

	var title_label := Label.new()
	title_label.text = "용병단"
	title_label.add_theme_font_size_override("font_size", 24)
	top_bar.add_child(title_label)

	# 닫기 버튼 (우측 상단)
	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.pressed.connect(_on_close_pressed)
	top_bar.add_child(_close_btn)

	# 메인 3 단 레이아웃
	_main_hbox = HBoxContainer.new()
	_main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main_hbox.add_theme_constant_override("separation", 12)
	main_vbox.add_child(_main_hbox)

	_build_unit_list_panel()
	_build_equipment_panel()
	_build_inventory_panel()


func _ready() -> void:
	if get_parent() is CanvasLayer:
		# 화면 중앙에 배치
		set_anchors_preset(Control.PRESET_CENTER)
		# 팝업 크기 설정 (화면의 80% x 70%)
		var viewport_size: Vector2 = get_viewport_rect().size
		var popup_width: float = viewport_size.x * 0.8
		var popup_height: float = viewport_size.y * 0.7

		# 앵커 기반 크기 설정
		anchor_left = 0.5 - popup_width / viewport_size.x / 2.0
		anchor_right = 0.5 + popup_width / viewport_size.x / 2.0
		anchor_top = 0.5 - popup_height / viewport_size.y / 2.0
		anchor_bottom = 0.5 + popup_height / viewport_size.y / 2.0

		offset_left = 0
		offset_right = 0
		offset_top = 0
		offset_bottom = 0

		process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func setup(party: Array[CombatUnit], inventory: Array[Item]) -> void:
	_party = party
	_inventory = inventory

	# 용병 리스트 구성
	_build_unit_list()

	# 인벤토리 구성
	_build_inventory_grid()

	# 첫 번째 용병 선택
	if _party.size() > 0:
		_select_unit(_party[0])

	# 장비 슬롯 초기화
	_init_equipment_slots()


func refresh() -> void:
	_build_unit_list()
	_build_inventory_grid()
	if _selected_unit != null:
		_update_equipment_display()


func show_popup() -> void:
	visible = true


func hide_popup() -> void:
	visible = false


func toggle_popup() -> void:
	visible = not visible


# ============================================================
# UI 빌드
# ============================================================


func _build_unit_list_panel() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 400)
	_main_hbox.add_child(panel)

	var panel_inner := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	panel_inner.add_theme_stylebox_override("panel", style)
	panel.add_child(panel_inner)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel_inner.add_child(vbox)

	var title := Label.new()
	title.text = "용병"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	_unit_list_scroll = ScrollContainer.new()
	_unit_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_unit_list_scroll)

	_unit_list = VBoxContainer.new()
	_unit_list.add_theme_constant_override("separation", 4)
	_unit_list_scroll.add_child(_unit_list)


func _build_equipment_panel() -> void:
	_equipment_panel = VBoxContainer.new()
	_equipment_panel.custom_minimum_size = Vector2(220, 400)
	_equipment_panel.add_theme_constant_override("separation", 8)
	_main_hbox.add_child(_equipment_panel)

	var panel_inner := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	panel_inner.add_theme_stylebox_override("panel", style)
	_equipment_panel.add_child(panel_inner)

	var inner_vbox := VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 8)
	panel_inner.add_child(inner_vbox)

	var title := Label.new()
	title.text = "장비"
	title.add_theme_font_size_override("font_size", 16)
	inner_vbox.add_child(title)

	# 장비 슬롯들
	var slots_vbox := VBoxContainer.new()
	slots_vbox.add_theme_constant_override("separation", 8)
	inner_vbox.add_child(slots_vbox)

	# 각 슬롯 생성
	_create_equipment_slot(slots_vbox, EquipmentSlotItem.EquipmentSlot.WEAPON)
	_create_equipment_slot(slots_vbox, EquipmentSlotItem.EquipmentSlot.HEAD)
	_create_equipment_slot(slots_vbox, EquipmentSlotItem.EquipmentSlot.BODY)
	_create_equipment_slot(slots_vbox, EquipmentSlotItem.EquipmentSlot.ACCESSORY)


func _create_equipment_slot(parent: Node, slot_type: EquipmentSlotItem.EquipmentSlot) -> void:
	var slot_item := EquipmentSlotItem.new()
	slot_item.setup(slot_type, null)
	slot_item.item_dropped.connect(_on_item_dropped_on_slot)
	slot_item.equipment_item_dropped.connect(_on_equipment_item_dropped_on_slot)
	_equipment_slots[slot_type] = slot_item
	parent.add_child(slot_item)


func _build_inventory_panel() -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(300, 400)
	_main_hbox.add_child(panel)

	var panel_inner := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	panel_inner.add_theme_stylebox_override("panel", style)
	panel.add_child(panel_inner)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel_inner.add_child(vbox)

	var title := Label.new()
	title.text = "인벤토리"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	_inventory_scroll = ScrollContainer.new()
	_inventory_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_inventory_scroll)

	_inventory_grid = GridContainer.new()
	_inventory_grid.columns = 4
	_inventory_grid.add_theme_constant_override("h_separation", 8)
	_inventory_grid.add_theme_constant_override("v_separation", 8)
	_inventory_scroll.add_child(_inventory_grid)


# ============================================================
# 데이터 바인딩
# ============================================================


func _build_unit_list() -> void:
	# 기존 카드들 제거
	for card in _unit_cards:
		card.queue_free()
	_unit_cards.clear()

	# 새 카드들 생성
	for unit in _party:
		var card := UnitCard.new()
		card.set_unit(unit)
		card.clicked.connect(_on_unit_card_clicked)
		_unit_list.add_child(card)
		_unit_cards.append(card)


func _build_inventory_grid() -> void:
	# 기존 아이템들 제거
	for child in _inventory_grid.get_children():
		child.queue_free()

	# 새 아이템들 추가
	for item in _inventory:
		var inv_item := InventoryItem.new()
		inv_item.custom_minimum_size = Vector2(100, 50)
		inv_item.set_item(item)
		_inventory_grid.add_child(inv_item)


func _init_equipment_slots() -> void:
	for slot_type in EquipmentSlotItem.EquipmentSlot.values():
		if _equipment_slots.has(slot_type):
			_equipment_slots[slot_type].clear_item()


func _select_unit(unit: CombatUnit) -> void:
	_selected_unit = unit

	# 모든 카드 선택 상태 업데이트
	for card in _unit_cards:
		card.set_selected(card.unit == unit)

	_update_equipment_display()


func _update_equipment_display() -> void:
	if _selected_unit == null:
		return

	# 각 슬롯에 현재 장비 표시
	if _equipment_slots.has(EquipmentSlotItem.EquipmentSlot.WEAPON):
		_equipment_slots[EquipmentSlotItem.EquipmentSlot.WEAPON].set_item(_selected_unit.weapon)
	if _equipment_slots.has(EquipmentSlotItem.EquipmentSlot.HEAD):
		_equipment_slots[EquipmentSlotItem.EquipmentSlot.HEAD].set_item(
			_selected_unit.head_armor_item
		)
	if _equipment_slots.has(EquipmentSlotItem.EquipmentSlot.BODY):
		_equipment_slots[EquipmentSlotItem.EquipmentSlot.BODY].set_item(
			_selected_unit.body_armor_item
		)
	if _equipment_slots.has(EquipmentSlotItem.EquipmentSlot.ACCESSORY):
		_equipment_slots[EquipmentSlotItem.EquipmentSlot.ACCESSORY].set_item(
			_selected_unit.accessory
		)


# ============================================================
# 이벤트 핸들러
# ============================================================


func _on_unit_card_clicked(unit: CombatUnit) -> void:
	_select_unit(unit)


func _on_item_dropped_on_slot(slot_type: EquipmentSlotItem.EquipmentSlot, item: Item) -> void:
	if _selected_unit == null:
		return

	# 현재 해당 슬롯에 장착된 아이템
	var current_item: Item = null
	match slot_type:
		EquipmentSlotItem.EquipmentSlot.WEAPON:
			current_item = _selected_unit.weapon
		EquipmentSlotItem.EquipmentSlot.HEAD:
			current_item = _selected_unit.head_armor_item
		EquipmentSlotItem.EquipmentSlot.BODY:
			current_item = _selected_unit.body_armor_item
		EquipmentSlotItem.EquipmentSlot.ACCESSORY:
			current_item = _selected_unit.accessory

	# 새 아이템으로 교체
	var slot_name := _get_slot_name(slot_type)
	_selected_unit.equip_item(slot_name, item)

	# 인벤토리에서 제거
	_inventory.erase(item)

	# 기존에 장착되어있던 아이템은 인벤토리로
	if current_item != null:
		_inventory.append(current_item)

	# UI 업데이트
	_update_equipment_display()
	_build_inventory_grid()

	# RNA 동기화
	_sync_party_to_rna()


func _on_equipment_item_dropped_on_slot(
	slot_type: EquipmentSlotItem.EquipmentSlot,
	dragged_item: Item,
	from_slot_type: EquipmentSlotItem.EquipmentSlot
) -> void:
	if _selected_unit == null:
		return

	# 같은 슬롯 타입이면 무시
	if slot_type == from_slot_type:
		return

	# 타입 호환성 확인
	if not _is_slot_compatible(slot_type, dragged_item):
		return

	# 대상 슬롯의 현재 아이템
	var target_item: Item = null
	match slot_type:
		EquipmentSlotItem.EquipmentSlot.WEAPON:
			target_item = _selected_unit.weapon
		EquipmentSlotItem.EquipmentSlot.HEAD:
			target_item = _selected_unit.head_armor_item
		EquipmentSlotItem.EquipmentSlot.BODY:
			target_item = _selected_unit.body_armor_item
		EquipmentSlotItem.EquipmentSlot.ACCESSORY:
			target_item = _selected_unit.accessory

	# 소스 슬롯에 대상 아이템 장착
	var from_slot_name := _get_slot_name(from_slot_type)
	_selected_unit.equip_item(from_slot_name, target_item)

	# 대상 슬롯에 드래그된 아이템 장착
	var to_slot_name := _get_slot_name(slot_type)
	_selected_unit.equip_item(to_slot_name, dragged_item)

	# UI 업데이트
	_update_equipment_display()

	# RNA 동기화
	_sync_party_to_rna()


func _is_slot_compatible(slot_type: EquipmentSlotItem.EquipmentSlot, item: Item) -> bool:
	if item == null:
		return true
	match slot_type:
		EquipmentSlotItem.EquipmentSlot.WEAPON:
			return item.type == Item.ItemType.WEAPON
		EquipmentSlotItem.EquipmentSlot.HEAD:
			return item.type == Item.ItemType.HEAD_ARMOR
		EquipmentSlotItem.EquipmentSlot.BODY:
			return item.type == Item.ItemType.BODY_ARMOR
		EquipmentSlotItem.EquipmentSlot.ACCESSORY:
			return item.type == Item.ItemType.ACCESSORY
	return false


func _get_slot_name(slot_type: EquipmentSlotItem.EquipmentSlot) -> String:
	match slot_type:
		EquipmentSlotItem.EquipmentSlot.WEAPON:
			return "weapon"
		EquipmentSlotItem.EquipmentSlot.HEAD:
			return "head"
		EquipmentSlotItem.EquipmentSlot.BODY:
			return "body"
		EquipmentSlotItem.EquipmentSlot.ACCESSORY:
			return "accessory"
	return ""


func _sync_party_to_rna() -> void:
	# SaveManager.rna["party"] 에 현재 파티 상태 저장
	if SaveManager.rna.has("party"):
		var party_data: Array = SaveManager.rna["party"]
		for i in range(_party.size()):
			if i < party_data.size():
				var unit := _party[i]
				var unit_data: Dictionary = party_data[i]
				# 장비 데이터 저장
				unit_data["weapon"] = _item_to_dict(unit.weapon)
				unit_data["head_armor_item"] = _item_to_dict(unit.head_armor_item)
				unit_data["body_armor_item"] = _item_to_dict(unit.body_armor_item)
				unit_data["accessory"] = _item_to_dict(unit.accessory)

	# SaveManager.rna["inventory"] 에 현재 인벤토리 저장
	var inventory_data: Array = []
	for item in _inventory:
		inventory_data.append(_item_to_dict(item))
	SaveManager.rna["inventory"] = inventory_data


func _item_to_dict(item: Item) -> Dictionary:
	if item == null:
		return {}
	return {
		"name": item.name,
		"type": item.type,
		"damage": item.damage,
		"armor_penetration": item.armor_penetration,
		"chance_to_hit_head": item.chance_to_hit_head,
		"head_armor": item.head_armor,
		"body_armor": item.body_armor,
		"hp": item.hp,
		"max_hp": item.max_hp,
		"action_points": item.action_points,
		"max_action_points": item.max_action_points,
		"fatigue": item.fatigue,
		"max_fatigue": item.max_fatigue,
		"morale": item.morale,
		"resolve": item.resolve,
		"initiative": item.initiative,
		"melee_skill": item.melee_skill,
		"ranged_skill": item.ranged_skill,
		"melee_defense": item.melee_defense,
		"ranged_defense": item.ranged_defense,
		"vision": item.vision,
	}


func _on_close_pressed() -> void:
	hide_popup()
