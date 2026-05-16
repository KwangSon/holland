class_name HudMenuPopup extends PanelContainer

var _vbox: VBoxContainer


func _init() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(_vbox)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_END
	visible = false


## Appends a labeled button. Always call after adding to the scene tree.
func add_item(text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.pressed.connect(
		func() -> void:
			visible = false
			callback.call()
	)
	_vbox.add_child(btn)


func toggle() -> void:
	visible = not visible
