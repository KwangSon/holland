class_name PauseMenuPopup extends PanelContainer

var _vbox: VBoxContainer


func _init() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(_vbox)


func _ready() -> void:
	if get_parent() is CanvasLayer:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		grow_horizontal = Control.GROW_DIRECTION_END
		grow_vertical = Control.GROW_DIRECTION_END
		process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func setup(items: Array[Dictionary]) -> void:
	# Clear existing buttons
	for child in _vbox.get_children():
		child.queue_free()

	# Add buttons from items
	for item: Dictionary in items:
		var label: String = item.get("label", "")
		var callback: Callable = item.get("callback", Callable())
		var is_todo: bool = item.get("is_todo", false)

		var btn := Button.new()
		btn.text = label
		if is_todo:
			btn.disabled = true
			btn.text += " (TODO)"
		elif callback.is_valid():
			btn.pressed.connect(
				func() -> void:
					visible = false
					callback.call()
			)
		_vbox.add_child(btn)


func toggle() -> void:
	visible = not visible


func show_menu() -> void:
	visible = true


func hide_menu() -> void:
	visible = false
