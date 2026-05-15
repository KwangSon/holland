extends Node2D


func _ready() -> void:
	ScreenManager.change_screen(ScreenManager.Screen.EXPLORE)
