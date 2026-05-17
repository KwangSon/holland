class_name FreeCamera extends Camera2D

@export var move_speed: float = 400.0


func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		position += direction * move_speed * delta
