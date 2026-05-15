## Autoload — 화면 전환 관리자.
## add_child / queue_free 패턴으로 화면을 동적으로 교체한다.
## 각 화면은 전환이 필요할 때 ScreenManager.change_screen()을 직접 호출한다.
extends Node2D

## 화면 전환이 완료되었을 때 발생한다.
signal screen_changed(from_screen: Screen, to_screen: Screen)

enum Screen {
	NONE,
	SPLASH,
	TITLE,
	COMBAT,
	# CUTSCENE,
	# GAME_OVER,
}

## 현재 활성 화면 타입.
var current_screen: Screen = Screen.NONE

## 현재 활성 화면 노드. null이면 화면 없음.
var _current_screen_node: Node = null


func _ready() -> void:
	pass


## 화면을 전환한다.
## 기존 화면을 queue_free 한 뒤, 새 화면을 생성하여 add_child 한다.
## data 딕셔너리는 새 화면의 initialize() 메서드에 전달된다.
func change_screen(target: Screen, data: Dictionary = {}) -> void:
	assert(target != Screen.NONE, "ScreenManager: cannot change to NONE screen")

	var from: Screen = current_screen

	_cleanup_current_screen()

	var new_screen: Node = _create_screen(target)
	assert(new_screen != null, "ScreenManager: failed to create screen %d" % target)

	_current_screen_node = new_screen
	current_screen = target
	add_child(new_screen)

	if new_screen.has_method("initialize"):
		new_screen.initialize(data)

	screen_changed.emit(from, target)


## 현재 화면 노드를 반환한다.
func get_current_screen_node() -> Node:
	return _current_screen_node


# ============================================================
# 화면 생성
# ============================================================


func _create_screen(target: Screen) -> Node:
	var screen: Node = null
	match target:
		Screen.SPLASH:
			screen = _create_splash_screen()
		Screen.TITLE:
			screen = _create_title_screen()
		Screen.COMBAT:
			screen = _create_combat_screen()
		# Screen.CUTSCENE:
		# 	screen = _create_cutscene_screen()
		# Screen.GAME_OVER:
		# 	screen = _create_game_over_screen()
		_:
			assert(false, "ScreenManager: unknown screen type %d" % target)
	assert(screen != null, "ScreenManager: failed to create screen %d" % target)
	return screen


func _create_splash_screen() -> Node:
	var screen = (preload("res://src/screen/splash_screen.gd") as GDScript).new()
	screen.name = "SplashScreen"
	return screen


func _create_title_screen() -> Node:
	var screen = (preload("res://src/screen/title_screen.gd") as GDScript).new()
	screen.name = "TitleScreen"
	return screen


func _create_combat_screen() -> Node:
	var screen = (preload("res://src/screen/combat_screen.gd") as GDScript).new()
	screen.name = "CombatScreen"
	return screen


# func _create_cutscene_screen() -> Node:
# 	var screen = (preload("res://src/screen/cutscene_screen.gd") as GDScript).new()
# 	screen.name = "CutsceneScreen"
# 	return screen

# func _create_game_over_screen() -> Node:
# 	var screen = (preload("res://src/screen/game_over_screen.gd") as GDScript).new()
# 	screen.name = "GameOverScreen"
# 	return screen

# ============================================================
# 정리
# ============================================================


func _cleanup_current_screen() -> void:
	if _current_screen_node == null:
		return

	if _current_screen_node.has_method("cleanup"):
		_current_screen_node.cleanup()

	_current_screen_node.queue_free()
	_current_screen_node = null
	current_screen = Screen.NONE
