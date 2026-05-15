## Autoload — 화면 전환 관리자.
## add_child / queue_free 패턴으로 화면을 동적으로 교체한다.
extends Node2D

## 화면 전환이 완료되었을 때 발생한다.
signal screen_changed(from_screen: Screen, to_screen: Screen)

enum Screen {
	NONE,
	SPLASH,
	TITLE,
	EXPLORATION,
	COMBAT,
	CUTSCENE,
	GAME_OVER,
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

	_connect_screen_signals(new_screen, target)

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
		Screen.EXPLORATION:
			screen = _create_exploration_screen()
		Screen.COMBAT:
			screen = _create_combat_screen()
		Screen.CUTSCENE:
			screen = _create_cutscene_screen()
		Screen.GAME_OVER:
			screen = _create_game_over_screen()
		_:
			assert(false, "ScreenManager: unknown screen type %d" % target)
	assert(screen != null, "ScreenManager: failed to create screen %d" % target)
	return screen


func _create_splash_screen() -> Node:
	# src/screen/splash_screen.gd가 있을 때 로드, 아직 없으면 빈 Node2D 반환 (에러 방지)
	if ResourceLoader.exists("res://src/screen/splash_screen.gd"):
		var screen = (preload("res://src/screen/splash_screen.gd") as GDScript).new()
		screen.name = "SplashScreen"
		return screen
	return _create_placeholder("SplashScreen")


func _create_title_screen() -> Node:
	if ResourceLoader.exists("res://src/screen/title_screen.gd"):
		var screen = (preload("res://src/screen/title_screen.gd") as GDScript).new()
		screen.name = "TitleScreen"
		return screen
	return _create_placeholder("TitleScreen")


func _create_exploration_screen() -> Node:
	if ResourceLoader.exists("res://src/screen/exploration_screen.gd"):
		var screen = (preload("res://src/screen/exploration_screen.gd") as GDScript).new()
		screen.name = "ExplorationScreen"
		return screen
	return _create_placeholder("ExplorationScreen")


func _create_combat_screen() -> Node:
	if ResourceLoader.exists("res://src/screen/combat_screen.gd"):
		var screen = (preload("res://src/screen/combat_screen.gd") as GDScript).new()
		screen.name = "CombatScreen"
		return screen
	return _create_placeholder("CombatScreen")


func _create_cutscene_screen() -> Node:
	if ResourceLoader.exists("res://src/screen/cutscene_screen.gd"):
		var screen = (preload("res://src/screen/cutscene_screen.gd") as GDScript).new()
		screen.name = "CutsceneScreen"
		return screen
	return _create_placeholder("CutsceneScreen")


func _create_game_over_screen() -> Node:
	if ResourceLoader.exists("res://src/screen/game_over_screen.gd"):
		var screen = (preload("res://src/screen/game_over_screen.gd") as GDScript).new()
		screen.name = "GameOverScreen"
		return screen
	return _create_placeholder("GameOverScreen")


func _create_placeholder(screen_name: String) -> Node:
	var placeholder := Node2D.new()
	placeholder.name = screen_name
	print("ScreenManager: Created placeholder for %s" % screen_name)
	return placeholder


# ============================================================
# 화면별 시그널 연결
# ============================================================


func _connect_screen_signals(screen_node: Node, screen_type: Screen) -> void:
	match screen_type:
		Screen.SPLASH:
			if screen_node.has_signal("splash_completed"):
				var err: int = screen_node.splash_completed.connect(_on_splash_completed)
				assert(err == OK, "ScreenManager: failed to connect splash_completed: %d" % err)
		Screen.TITLE:
			if screen_node.has_signal("new_game_requested"):
				var err: int = screen_node.new_game_requested.connect(_on_new_game_requested)
				assert(err == OK, "ScreenManager: failed to connect new_game_requested: %d" % err)
			if screen_node.has_signal("load_game_requested"):
				var err: int = screen_node.load_game_requested.connect(_on_load_game_requested)
				assert(err == OK, "ScreenManager: failed to connect load_game_requested: %d" % err)
		Screen.EXPLORATION:
			if screen_node.has_signal("combat_requested"):
				var err: int = screen_node.combat_requested.connect(_on_combat_requested)
				assert(err == OK, "ScreenManager: failed to connect combat_requested: %d" % err)
			if screen_node.has_signal("cutscene_requested"):
				var err: int = screen_node.cutscene_requested.connect(_on_cutscene_requested)
				assert(err == OK, "ScreenManager: failed to connect cutscene_requested: %d" % err)
		Screen.COMBAT:
			if screen_node.has_signal("combat_ended"):
				var err: int = screen_node.combat_ended.connect(_on_combat_ended)
				assert(err == OK, "ScreenManager: failed to connect combat_ended: %d" % err)
			if screen_node.has_signal("game_over"):
				var err: int = screen_node.game_over.connect(_on_game_over)
				assert(err == OK, "ScreenManager: failed to connect game_over: %d" % err)
		Screen.CUTSCENE:
			if screen_node.has_signal("cutscene_ended"):
				var err: int = screen_node.cutscene_ended.connect(_on_cutscene_ended)
				assert(err == OK, "ScreenManager: failed to connect cutscene_ended: %d" % err)
		Screen.GAME_OVER:
			if screen_node.has_signal("return_to_title_requested"):
				var err: int = screen_node.return_to_title_requested.connect(
					_on_return_to_title_requested
				)
				assert(
					err == OK,
					"ScreenManager: failed to connect return_to_title_requested: %d" % err
				)


# ============================================================
# 시그널 콜백
# ============================================================


func _on_splash_completed() -> void:
	change_screen(Screen.TITLE)


func _on_new_game_requested() -> void:
	SaveManager.rna = SaveManager._default_rna()
	(SaveManager.rna["world"] as Dictionary)["current_map_id"] = GameManager.STARTING_MAP_ID
	(SaveManager.rna["player"] as Dictionary)["cell"] = GameManager.STARTING_SPAWN
	change_screen(Screen.CUTSCENE, {"cutscene_id": "intro"})
	if _current_screen_node.has_method("play"):
		_current_screen_node.call("play")


func _on_load_game_requested(slot: int) -> void:
	var ok := SaveManager.load_game(slot)
	assert(ok, "ScreenManager: load_game failed for slot %d" % slot)
	change_screen(Screen.EXPLORATION)


func _on_combat_requested() -> void:
	change_screen(Screen.COMBAT)


func _on_combat_ended(win: bool) -> void:
	if win:
		change_screen(Screen.EXPLORATION)
	else:
		change_screen(Screen.GAME_OVER)


func _on_cutscene_requested(cutscene_id: String) -> void:
	change_screen(Screen.CUTSCENE, {"cutscene_id": cutscene_id})


func _on_cutscene_ended() -> void:
	change_screen(Screen.EXPLORATION)


func _on_game_over() -> void:
	change_screen(Screen.GAME_OVER)


func _on_return_to_title_requested() -> void:
	change_screen(Screen.TITLE)


# ============================================================
# 정리
# ============================================================


func _cleanup_current_screen() -> void:
	if _current_screen_node == null:
		return

	_disconnect_screen_signals(_current_screen_node, current_screen)

	if _current_screen_node.has_method("cleanup"):
		_current_screen_node.cleanup()

	_current_screen_node.queue_free()
	_current_screen_node = null
	current_screen = Screen.NONE


func _disconnect_screen_signals(screen_node: Node, screen_type: Screen) -> void:
	match screen_type:
		Screen.SPLASH:
			if screen_node.has_signal("splash_completed"):
				if screen_node.splash_completed.is_connected(_on_splash_completed):
					screen_node.splash_completed.disconnect(_on_splash_completed)
		Screen.TITLE:
			if screen_node.has_signal("new_game_requested"):
				if screen_node.new_game_requested.is_connected(_on_new_game_requested):
					screen_node.new_game_requested.disconnect(_on_new_game_requested)
			if screen_node.has_signal("load_game_requested"):
				if screen_node.load_game_requested.is_connected(_on_load_game_requested):
					screen_node.load_game_requested.disconnect(_on_load_game_requested)
		Screen.EXPLORATION:
			if screen_node.has_signal("combat_requested"):
				if screen_node.combat_requested.is_connected(_on_combat_requested):
					screen_node.combat_requested.disconnect(_on_combat_requested)
			if screen_node.has_signal("cutscene_requested"):
				if screen_node.cutscene_requested.is_connected(_on_cutscene_requested):
					screen_node.cutscene_requested.disconnect(_on_cutscene_requested)
		Screen.COMBAT:
			if screen_node.has_signal("combat_ended"):
				if screen_node.combat_ended.is_connected(_on_combat_ended):
					screen_node.combat_ended.disconnect(_on_combat_ended)
			if screen_node.has_signal("game_over"):
				if screen_node.game_over.is_connected(_on_game_over):
					screen_node.game_over.disconnect(_on_game_over)
		Screen.CUTSCENE:
			if screen_node.has_signal("cutscene_ended"):
				if screen_node.cutscene_ended.is_connected(_on_cutscene_ended):
					screen_node.cutscene_ended.disconnect(_on_cutscene_ended)
		Screen.GAME_OVER:
			if screen_node.has_signal("return_to_title_requested"):
				if screen_node.return_to_title_requested.is_connected(
					_on_return_to_title_requested
				):
					screen_node.return_to_title_requested.disconnect(_on_return_to_title_requested)
