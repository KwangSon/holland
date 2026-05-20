class_name UnitCard extends PanelContainer

signal clicked(unit: CombatUnit)

var unit: CombatUnit
var selected: bool = false

var _vbox: VBoxContainer
var _name_label: Label
var _level_label: Label
var _sprite: TextureRect


func _init() -> void:
	# 스타일 설정
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 0.8)
	add_theme_stylebox_override("panel", style)

	# 레이아웃
	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 4)
	add_child(_vbox)

	# 스프라이트
	_sprite = TextureRect.new()
	_sprite.custom_minimum_size = Vector2(64, 64)
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_vbox.add_child(_sprite)

	# 이름
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 14)
	_vbox.add_child(_name_label)

	# 레벨
	_level_label = Label.new()
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.add_theme_font_size_override("font_size", 12)
	_vbox.add_child(_level_label)

	# 클릭 가능하게
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _ready() -> void:
	pass


func set_unit(u: CombatUnit) -> void:
	unit = u
	_name_label.text = u.display_name
	_level_label.text = "Lv." + str(u.level)
	_sprite.texture = u.sprite_texture
	_update_style()


func set_selected(is_selected: bool) -> void:
	selected = is_selected
	_update_style()


func _update_style() -> void:
	var style := StyleBoxFlat.new()
	if selected:
		style.bg_color = Color(0.3, 0.4, 0.6, 0.9)
		style.border_color = Color(0.6, 0.7, 0.9, 1.0)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
	else:
		style.bg_color = Color(0.2, 0.2, 0.25, 0.8)
	add_theme_stylebox_override("panel", style)


func _on_mouse_entered() -> void:
	if not selected:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.25, 0.25, 0.3, 0.9)
		add_theme_stylebox_override("panel", style)


func _on_mouse_exited() -> void:
	if not selected:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.25, 0.8)
		add_theme_stylebox_override("panel", style)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(unit)
