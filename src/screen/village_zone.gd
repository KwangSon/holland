## 마을/POI 영역 — 마우스 hover 시 커서 변경, 마커 도달 시 전투 화면 전환.
## ExploreScreen에서 코드로 생성하여 사용한다.
class_name VillageZone extends Area2D

signal marker_entered(zone: VillageZone)

## 지역 표시 이름 (UI 툴팁 등에 활용).
var zone_name: String = ""

## 전투 인카운터 데이터 — SaveManager.rna["encounter"]에 저장될 딕셔너리.
var encounter_data: Dictionary = {}

var _label: Label


func _init() -> void:
	# Area2D 기본 설정 — 입력 감지 활성화
	input_pickable = true
	monitoring = true
	monitorable = false


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_build_label()


## 원형 충돌 영역을 생성한다.
static func create_zone(
	p_name: String,
	p_position: Vector2,
	p_radius: float,
	p_encounter: Dictionary,
) -> VillageZone:
	var zone := VillageZone.new()
	zone.name = p_name.replace(" ", "_")
	zone.zone_name = p_name
	zone.position = p_position
	zone.encounter_data = p_encounter

	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape"
	var circle := CircleShape2D.new()
	circle.radius = p_radius
	shape.shape = circle
	zone.add_child(shape)

	return zone


## 마커(CharacterBody2D 또는 Area2D)가 이 영역에 도달했는지 검사한다.
## ExploreScreen에서 마커 이동 완료 시 호출.
func check_marker_overlap(marker_pos: Vector2) -> bool:
	var shape: CollisionShape2D = get_node("CollisionShape")
	assert(shape != null, "VillageZone: missing CollisionShape")
	var circle: CircleShape2D = shape.shape as CircleShape2D
	assert(circle != null, "VillageZone: shape is not CircleShape2D")
	return marker_pos.distance_to(global_position) <= circle.radius


# ============================================================
# 마우스 커서
# ============================================================


func _on_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	if _label != null:
		_label.visible = true


func _on_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if _label != null:
		_label.visible = false


# ============================================================
# UI
# ============================================================


func _build_label() -> void:
	_label = Label.new()
	_label.text = zone_name
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-40, -50)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.visible = false
	add_child(_label)
