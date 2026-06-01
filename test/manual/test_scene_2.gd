# 무너지는 기둥 사이로 펼쳐지는 참혹한 백병전.
# 우리의 주인공(용병대장)과 부하들이 피투성이가 된 채 적의 포위망을 뚫고 있습니다.
# 주인공이 적의 창을 튕겨내고, 순식간에 두 번째 칼을 뽑아 적의 목을 잔혹하고 깔끔하게 베어버립니다(기획안의 참수 연출).

extends Node2D

@onready var samurai: Node2D = $Samurai

## 적 배치 오프셋 (상, 우, 하)
const ENEMY_OFFSETS: Array[Vector2] = [
	Vector2(200, -300),   # 상
	Vector2(400, 0),    # 우
	Vector2(200, 300),    # 하
]

const SWING_FRAMES: Array[String] = ["S1", "S2", "S3", "S4", "S5"]

## Enemy2 애니메이션 중 Samurai 넉백 오프셋 (S1→S5 + S1 복귀)
const SAMURAI_KNOCKBACK_OFFSETS: Array[int] = [-10, -10, -10, 10, 10, 10]

## 머리 낙하 물리 상수
const HEAD_INITIAL_VELOCITY: float = -150.0  # 위로 튕기는 초기 속도
const HEAD_GRAVITY: float = 600.0            # 중력 가속도
const HEAD_ROTATION_SPEED: float = 8.0       # 회전 속도 (rad/s)
const HEAD_GROUND_Y: float = 0.0           # 머리가 멈추는 바닥 Y좌표 (월드 기준)

## 프레임 전환 간격 (초)
@export var frame_interval: float = 0.1

var _actors: Array[Node2D] = []
var _current_actor_index: int = 0
var _is_animating: bool = false
var _current_frame: int = 0
var _elapsed: float = 0.0
var _samurai_origin: Vector2 = Vector2.ZERO

## 머리 낙하 상태
var _is_head_falling: bool = false
var _head_node: Sprite2D = null
var _head_velocity_y: float = 0.0


func _ready() -> void:
	_setup_samurai()
	_setup_enemies()
	# Enemy2 먼저, 그 다음 Samurai
	_actors = [get_node("Enemy2") as Node2D, samurai]
	_samurai_origin = samurai.position


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not _is_animating and not _is_head_falling:
		if _current_actor_index < _actors.size():
			_start_swing_animation(_actors[_current_actor_index])


func _process(delta: float) -> void:
	# 검 프레임 애니메이션
	if _is_animating:
		_elapsed += delta
		if _elapsed >= frame_interval:
			_elapsed = 0.0
			_advance_swing_frame()

	# 머리 낙하 애니메이션
	if _is_head_falling:
		_head_velocity_y += HEAD_GRAVITY * delta
		_head_node.global_position.y += _head_velocity_y * delta
		_head_node.rotation += HEAD_ROTATION_SPEED * delta

		# 바닥에 닿으면 멈춤
		if _head_node.global_position.y >= HEAD_GROUND_Y:
			_head_node.global_position.y = HEAD_GROUND_Y
			_is_head_falling = false


## Samurai 노드의 S2~S5 visible을 끄고 초기 상태 설정
func _setup_samurai() -> void:
	for child_name: String in ["S2", "S3", "S4", "S5"]:
		var child: CanvasItem = samurai.get_node(child_name) as CanvasItem
		if child:
			child.visible = false


## Samurai를 복사해 enemy 1,2,3을 생성하고 좌우 대칭 + 배치
func _setup_enemies() -> void:
	for i: int in range(3):
		var enemy: Node2D = samurai.duplicate() as Node2D
		enemy.name = "Enemy%d" % (i + 1)
		enemy.position = ENEMY_OFFSETS[i]
		enemy.scale.x = -1  # 좌우 대칭
		add_child(enemy)


## 지정된 액터의 검 프레임 애니메이션 시작
func _start_swing_animation(actor: Node2D) -> void:
	_is_animating = true
	_current_frame = 0
	_elapsed = 0.0
	# S1만 보이도록 초기화
	for frame_name: String in SWING_FRAMES:
		var child: CanvasItem = actor.get_node(frame_name) as CanvasItem
		if child:
			child.visible = (frame_name == "S1")


## 현재 액터의 프레임을 한 단계 전진
func _advance_swing_frame() -> void:
	var actor: Node2D = _actors[_current_actor_index]

	# 현재 프레임 끄기
	var current_child: CanvasItem = actor.get_node(SWING_FRAMES[_current_frame]) as CanvasItem
	if current_child:
		current_child.visible = false

	_current_frame += 1

	# Enemy2 애니메이션 중 Samurai 넉백 이동
	if _current_actor_index == 0 and _current_frame < SAMURAI_KNOCKBACK_OFFSETS.size():
		samurai.position.x += SAMURAI_KNOCKBACK_OFFSETS[_current_frame]

	# S5까지 갔으면 S1으로 돌아가고 애니메이션 종료
	if _current_frame >= SWING_FRAMES.size():
		var first_child: CanvasItem = actor.get_node(SWING_FRAMES[0]) as CanvasItem
		if first_child:
			first_child.visible = true
		_is_animating = false
		_current_actor_index += 1

		# Samurai 검 애니메이션 종료 후 Enemy2 머리 낙하 시작
		if _current_actor_index > _actors.size() - 1:
			_start_head_fall()
		return

	# 다음 프레임 켜기
	var next_child: CanvasItem = actor.get_node(SWING_FRAMES[_current_frame]) as CanvasItem
	if next_child:
		next_child.visible = true


## Enemy2의 H3(머리)를 분리하고 낙하 애니메이션 시작
func _start_head_fall() -> void:
	var enemy2: Node2D = get_node("Enemy2") as Node2D
	_head_node = enemy2.get_node("H3") as Sprite2D

	# 글로벌 위치 보존 후 reparent
	var head_global_pos: Vector2 = _head_node.global_position
	enemy2.remove_child(_head_node)
	add_child(_head_node)
	_head_node.global_position = head_global_pos

	# 낙하 초기화
	_head_velocity_y = HEAD_INITIAL_VELOCITY
	_is_head_falling = true
