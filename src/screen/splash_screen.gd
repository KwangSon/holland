class_name SplashScreen extends Node2D

signal splash_completed

var _timer: Timer


func _ready() -> void:
	_setup_ui()
	_start_splash()


func initialize(_data: Dictionary) -> void:
	pass


func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)

	var label := Label.new()
	label.text = "JTE: Journey To East\n\n(Splash Screen)"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(label)


func _start_splash() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = 1.5
	var err := _timer.timeout.connect(_on_timeout)
	assert(err == OK, "SplashScreen: failed to connect timeout: %d" % err)
	add_child(_timer)
	_timer.start()


func _on_timeout() -> void:
	splash_completed.emit()
