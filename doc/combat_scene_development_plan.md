# 전투 씬 개발 계획

## 목표

`holland`의 전투 씬은 Battle Brothers식 전술 전투를 매우 가깝게 재현하는 것을
목표로 한다. 단, 원작의 텍스트, 명칭, 아트, 고유 설정, 표 데이터를 그대로 복사하지
않고 전투 규칙의 구조와 플레이 감각을 구현 대상으로 삼는다.

이 문서는 전투 화면(`src/screen/combat_screen.gd`)과 전투 도메인
(`src/combat/`)을 우선 완성하기 위한 개발 계획이다. 프로젝트 원칙에 따라 새 `.tscn`
파일은 만들지 않고, 화면 구성과 데이터는 GDScript에서 만든다.

## 참고 자료

- Battle Brothers Wiki - Combat Mechanics:
  https://battlebrothers.fandom.com/wiki/Combat_Mechanics
- Battle Brothers Wiki - Hit Chance:
  https://battlebrothers.fandom.com/wiki/Hit_Chance
- Battle Brothers Wiki - Damage:
  https://battlebrothers.fandom.com/wiki/Damage
- Battle Brothers Wiki - Skills:
  https://battlebrothers.fandom.com/wiki/Skills
- Battle Brothers Wiki - Status Effects:
  https://battlebrothers.fandom.com/wiki/Status_Effects
- Battle Brothers Wiki - Damage:
  https://battlebrothers.fandom.com/wiki/Damage
- Battle Brothers Wiki - Perks:
  https://battlebrothers.fandom.com/wiki/Perks
- Battle Brothers Wiki - Weapons:
  https://battlebrothers.fandom.com/wiki/Weapons
- Battle Brothers Wiki - Ammunition:
  https://battlebrothers.fandom.com/wiki/Ammunition

위키는 일부 항목이 오래되었다고 표시되어 있으므로, 구현 기준은 "체감과 구조를
맞추는 참고값"으로 사용한다. 수치가 충돌하면 먼저 현재 프로젝트의 테스트 가능한
규칙을 확정하고, 이후 원작 플레이 검증으로 조정한다.

## 현재 상태

이미 있는 주요 파일:

- `src/screen/combat_screen.gd`: 코드 기반 전투 화면, 헥스 타일 렌더링, 유닛 표시,
  선택, 이동, 공격, 결과 팝업을 포함한다.
- `src/combat/combat_board.gd`: 유효 셀, 점유 셀, 인접 셀, 이동 가능 셀, AStar 경로
  탐색을 담당한다.
- `src/combat/combat_state.gd`: 전투 상태, 유닛 목록, 턴 진행, 이동/공격 적용,
  승패 판정을 담당한다.
- `src/combat/combat_rules.gd`: 이동 가능 셀, 공격 대상, 공격 판정, 피해 적용,
  승패 판정을 담당한다.
- `src/combat/combat_unit.gd`: 유닛 능력치, 장비 슬롯, 전투 상태를 보관한다.

현재 구현은 전투 알파 기반 규칙을 갖춘 상태다. AP/피로도, 지형/고도 이동 비용,
명중률, 머리/몸 방어구와 HP 피해, ZoC, 원거리 사거리/탄약/사격선, 사기 체크,
핵심 상태 이상, AP 기반 AI가 들어가 있다. `CombatScreen`은 이동/공격 예측 UI와
로그를 통해 현재 규칙 결과를 표시한다.

현재 유닛 데이터 구현 상태:

- `src/data/unit_registry.gd`의 플레이어 유닛은 `성직자`, `해부학자`, `궁수` 3명만
  있으며, 수동 전투 진입과 Explore 기본 파티에서 이 구조를 사용한다.
- `src/data/unit_registry.gd`의 기존 적 유닛 2명 구조는 남아 있지만, 전투 알파 검증용
  적은 `EnemyRegistry`와 `EncounterRegistry`로 분리되었다.
- `EnemyRegistry`에는 산적 3종, 언데드 2종, 야수 2종이 등록되어 있다.
- `EncounterRegistry`에는 산적/언데드/야수 기본 조우가 있고, `CombatScreen`은
  `encounter_id`를 통해 이 조우를 생성할 수 있다.
- `CombatUnit.UnitType`도 위 5종만 정의되어 있다.
- `BrotherData`, 형제단 배경, 전체 적 로스터, 챔피언 변형, 특성/퍽 전체 보정,
  시야/안개, 도망 AI, 부상 심화, 전투 후 XP/전리품 반영은 아직 구현되어 있지 않다.
- 따라서 현재 기준으로는 "전투 알파 기반 구현은 완료, Battle Brothers식 전체
  콘텐츠/캠페인 재현은 후속 확장" 상태다.

## 형제단/용병 데이터 목표

Battle Brothers Wiki의 `Character Backgrounds`, `Attribute Ranges`, `Attributes`,
`Talents`, `Traits`, `Perks`, `Level and Experience` 항목을 기준으로 형제단 데이터를
분리한다.

핵심 원칙:

- `CombatUnit`은 전투 중 변하는 상태만 가진다.
- 영구 캐릭터 정보는 별도 데이터 구조인 `BrotherData`에 둔다.
- 출신 배경은 `BrotherBackgroundData`로 분리한다.
- 전투 진입 시 `BrotherData`와 장비에서 `CombatUnit`을 생성한다.
- 위키의 설명 텍스트와 고유 문구는 복사하지 않고, 수치 구조와 시스템만 반영한다.

필수 데이터 구조:

```gdscript
class_name BrotherBackgroundData

var id: String = ""
var display_name: String = ""
var tier_min: int = 1
var tier_max: int = 1
var hiring_cost_range: Vector2i = Vector2i.ZERO
var daily_wage_range: Vector2i = Vector2i.ZERO
var attribute_ranges: Dictionary = {}
var allowed_trait_ids: Array[String] = []
var excluded_trait_ids: Array[String] = []
var talent_bias: Dictionary = {}
var starting_equipment_pool: Array[String] = []
var affiliation_tags: Array[String] = []
var settlement_spawn_tags: Array[String] = []
var event_tags: Array[String] = []
```

```gdscript
class_name BrotherData

var id: String = ""
var display_name: String = ""
var background_id: String = ""
var level: int = 1
var xp: int = 0
var attributes: Dictionary = {}
var talents: Dictionary = {}
var trait_ids: Array[String] = []
var perk_ids: Array[String] = []
var injury_ids: Array[String] = []
var mood_state: String = "steady"
var wage: int = 0
var equipment: Dictionary = {}
```

형제단 배경 구현 범위:

- 모든 배경은 하나의 레지스트리에서 관리한다.
- 각 배경은 HP, 피로도, 결의, 이니셔티브, 근접 스킬, 원거리 스킬, 근접 방어,
  원거리 방어의 시작 범위를 가진다.
- 시작 레벨 범위와 고용 비용/임금 범위를 가진다.
- 시작 장비 풀을 가진다.
- 등장 가능한 정착지/상황 태그를 가진다.
- 허용/제외 특성 규칙을 가진다.
- 배경별 이벤트 태그를 가진다.
- 배경별 재능 제한 또는 경향을 가진다.

최소 완료 기준:

- `BrotherBackgroundRegistry.get_all()`이 전체 배경 목록을 반환한다.
- 각 배경은 8개 핵심 능력치 범위를 모두 가진다.
- 배경에서 생성한 형제는 같은 seed에서 항상 같은 결과를 만든다.
- 배경별 허용/제외 특성 검사가 통과한다.
- 생성된 형제는 `CombatUnit.from_brother()`로 전투에 투입될 수 있다.
- 테스트에서 "등록된 배경 수"와 "필수 필드 누락 없음"을 검사한다.

구현 순서:

1. 현재 `UnitRegistry.player_units()`의 하드코딩 3명을 `BrotherData` 기반 생성으로
   바꾼다.
2. `BrotherBackgroundData`와 `BrotherBackgroundRegistry`를 추가한다.
3. 시작 캠페인용 낮은 티어 배경부터 등록한다.
4. 전투 테스트용 중간/상위 티어 배경을 추가한다.
5. 전체 배경을 등록하고 누락 검사용 테스트를 추가한다.

## 적 로스터 데이터 목표

Battle Brothers Wiki의 `Enemies` 항목을 기준으로 적을 파벌, 병종, 변형, 챔피언
여부로 나눈다.

핵심 원칙:

- 적도 `CombatUnit`을 직접 하드코딩하지 않는다.
- 영구 로스터 정의는 `EnemyArchetypeData`로 분리한다.
- 실제 조우는 `EncounterData`가 적 archetype id와 수량, 장비 변형, 전장 조건을
  조합해 만든다.
- 챔피언은 별도 유닛이 아니라 `champion_variant` 규칙으로 강화한다.
- 원작 토큰/아이콘/설명문은 사용하지 않고 프로젝트 자체 에셋을 붙인다.

필수 데이터 구조:

```gdscript
class_name EnemyArchetypeData

var id: String = ""
var display_name: String = ""
var faction_id: String = ""
var role_tags: Array[String] = []
var attributes: Dictionary = {}
var skill_ids: Array[String] = []
var trait_ids: Array[String] = []
var perk_ids: Array[String] = []
var equipment_pool: Dictionary = {}
var ai_profile_id: String = ""
var morale_profile_id: String = ""
var can_be_champion: bool = false
var spawn_weight: int = 1
var threat_value: int = 1
```

로스터 파벌 범위:

- 인간계: 산적, 유목민, 야만인, 귀족군, 도시국가 병력, 민병/상단, 용병단, 이벤트
  인간 적.
- 언데드: 되살아난 시체 계열, 망령 계열, 사령술사 계열, 고대 언데드 계열.
- 그린스킨: 오크 계열, 고블린 계열, 공성 장비.
- 야수: 거미, 늑대, 하이에나, 구울형 포식자, 뱀, 악몽형 적, 거대 야수, 나무형 적,
  대형 보스형 적.
- 동물/부속 유닛: 개, 늑대, 당나귀 등 전투 또는 호위 목적 유닛.
- 특수/전설 조우: 일반 로스터와 분리된 전용 encounter id로 관리한다.

적 병종 역할 태그:

- `frontline`: 전열 근접.
- `shield`: 방패/방어형.
- `two_hander`: 고피해 양손 무기.
- `polearm`: 2칸 근접 공격.
- `ranged`: 원거리 공격.
- `thrower`: 투척 무기.
- `support`: 버프/디버프/소환.
- `beast`: 장비 없는 자연/괴물형.
- `fast_flanker`: 고기동 측면 공격.
- `summoner`: 소환 또는 부활.
- `boss`: 전설/보스 조우.

최소 완료 기준:

- `EnemyRegistry.get_all()`이 위 파벌 범위 전체를 반환한다.
- 각 적 archetype은 능력치, 스킬, 장비 풀, AI 프로필을 가진다.
- 챔피언 가능 적은 챔피언 변형 규칙을 가진다.
- 적 생성은 같은 seed에서 장비와 능력치 변형이 항상 같다.
- 조우 생성기는 파벌/난이도/계약 태그로 적 구성을 만들 수 있다.
- 테스트에서 "파벌별 최소 1개 이상 등록", "필수 필드 누락 없음", "전투 생성 가능"을
  검사한다.

구현 순서:

1. 현재 `UnitRegistry.enemy_units()`의 2명을 `EnemyRegistry` 기반 생성으로 바꾼다.
2. 산적 계열을 먼저 구현한다. 전투 기본기를 검증하기 가장 좋다.
3. 언데드 기본형을 추가한다. 사기 면역, 피로도, 부활/소환 규칙 검증용이다.
4. 야수 기본형을 추가한다. 장비 없는 유닛, 고기동 AI, 특수 상태 검증용이다.
5. 오크/고블린 계열을 추가한다. 밀치기, 원거리 압박, 사기/ZoC 변형 검증용이다.
6. 귀족군/도시국가/용병단을 추가한다. 장비 다양성과 고급 AI 검증용이다.
7. 챔피언과 전설 조우는 전투 핵심 규칙이 안정된 뒤 추가한다.

## 전투 규칙 목표

### 1. 전장

전장은 헥스 그리드 기반이다.

필수 구현:

- 유효 타일과 비유효 타일 구분.
- 타일별 지형 타입.
- 타일별 이동 AP 비용.
- 타일별 이동 피로도 비용.
- 타일별 고도.
- 점유 셀 관리.
- 인접 6방향 판정.
- 거리 계산.
- 경로 탐색.

초기 지형 타입:

- 평지: 이동 2 AP.
- 거친 지형: 이동 3 AP.
- 늪/진흙: 이동 4 AP.
- 고도 차이: 이동할 때 높이가 바뀌면 추가 AP 비용.
- 장애물/비전투 타일: 이동 불가.

구현 위치:

- `CombatBoard`에 `terrain_by_cell`, `height_by_cell` 추가.
- `CombatRules.get_move_cost()`와 `get_path_cost()` 추가.
- 기존 `MOVE_RANGE` 상수 기반 이동을 AP 기반 이동으로 교체.

### 1-1. 전장 고도

Battle Brothers 위키 기준으로 전장 타일에는 0-3단계의 고도 레벨이 있다. 고도는
단순 시각 효과가 아니라 이동, 명중률, 사거리, 시야, 근접 교전 가능 여부, ZoC에
직접 영향을 준다.

위키 기반 목표 규칙:

- 고도 레벨은 `0`, `1`, `2`, `3` 네 단계로 둔다.
- 같은 높이로 이동할 때는 지형의 기본 AP 비용만 사용한다.
- 높이가 바뀌는 타일로 이동하면 이동 AP 비용에 추가 비용을 붙인다.
- 초기 구현의 고도 변경 AP 추가 비용은 `+1 AP`로 둔다.
- 고도 변경은 피로도 비용도 증가시킨다. 정확한 피로도 증가는 별도 밸런싱 값으로
  두되, 기본값은 `+5 fatigue`로 시작한다.
- Pathfinder 계열 특성은 고도 변경의 AP 추가 비용을 제거한다.
- 공격자가 대상보다 높은 타일에 있으면 명중률 보너스를 받는다.
- 공격자가 대상보다 낮은 타일에 있으면 명중률 패널티를 받는다.
- 초기 구현은 `height_bonus = sign(attacker_height - defender_height) * 10`으로 둔다.
- 원거리 공격은 공격자가 높은 곳에 있을 때 고도 1단계마다 최대 사거리를 1칸 늘린다.
- 고지대는 낮은 위치의 대상 또는 낮은 지형을 볼 때 시야 이점을 준다.
- 인접한 적이라도 고도 차이가 2 이상이면 근접 공격 범위로 보지 않는다.
- 인접한 적이라도 고도 차이가 2 이상이면 서로 ZoC를 만들지 않는다.

명중률 세부 기준:

```text
height_delta = attacker_height - defender_height

if height_delta > 0:
    hit_chance += 10
elif height_delta < 0:
    hit_chance -= 10 * abs(height_delta)
```

위키의 설명은 페이지에 따라 "높으면 +10"과 "낮으면 레벨 차이당 -10"으로 표현된다.
초기 구현은 위 공식을 사용하고, 원작 플레이 검증에서 높은 위치 보너스가 레벨 차이당
누적되는지 확인한 뒤 조정한다.

근접/ZoC 판정:

```text
height_delta_abs = abs(attacker_height - defender_height)

can_melee_attack = board.are_adjacent(attacker.position, defender.position)
    and height_delta_abs <= 1

can_exert_zoc = has_melee_control(unit)
    and abs(unit_height - target_cell_height) <= 1
```

원거리 사거리:

```text
effective_range = skill.base_range
if attacker_height > target_height:
    effective_range += attacker_height - target_height
```

초기 데이터 모델:

```gdscript
enum TerrainType {
    PLAIN,
    ROUGH,
    SWAMP,
    BLOCKED,
}

class CombatTileData:
    var terrain: TerrainType = TerrainType.PLAIN
    var height: int = 0
```

`CombatBoard`는 최소한 아래 API를 제공해야 한다.

```gdscript
func get_height(cell: Vector2i) -> int
func set_height(cell: Vector2i, height: int) -> void
func get_terrain(cell: Vector2i) -> int
func set_terrain(cell: Vector2i, terrain: int) -> void
func get_step_ap_cost(from: Vector2i, to: Vector2i, unit: CombatUnit) -> int
func get_step_fatigue_cost(from: Vector2i, to: Vector2i, unit: CombatUnit) -> int
func is_melee_reachable(attacker_cell: Vector2i, defender_cell: Vector2i) -> bool
```

전투 화면 표시:

- 타일 호버 시 지형 타입, 높이, 이동 AP 비용, 이동 피로도 비용을 표시한다.
- 높이 0-3은 타일 위 작은 숫자 또는 색상 명암으로 구분한다.
- 선택 유닛보다 높은 타일은 고지대 표시를 한다.
- 원거리 스킬 선택 시 고도 보정이 반영된 사거리 경계를 보여준다.
- 근접 불가인 고도 차이 2 이상 인접 적은 공격 가능 표시에서 제외한다.
- ZoC 표시도 고도 차이 2 이상 타일에는 표시하지 않는다.

테스트 항목:

- 높이 값은 0-3 범위 밖으로 설정할 수 없다.
- 같은 지형/같은 높이 이동은 기본 AP 비용만 소비한다.
- 높이가 바뀌는 이동은 AP 추가 비용을 소비한다.
- Pathfinder 계열 특성은 고도 AP 추가 비용을 제거한다.
- 고지대 공격은 명중률 보너스를 받는다.
- 저지대 공격은 명중률 패널티를 받는다.
- 고도 차이 1인 인접 적은 근접 공격 가능하다.
- 고도 차이 2인 인접 적은 근접 공격 불가하다.
- 고도 차이 2인 인접 적은 ZoC를 만들지 않는다.
- 높은 위치의 원거리 유닛은 낮은 대상에게 더 긴 사거리를 가진다.

### 2. 행동 경제

전투 유닛은 매 라운드 시작 시 AP가 회복되고, 각 행동은 AP와 피로도를 소비한다.

기본 목표:

- 대부분 유닛의 기본 AP는 9.
- 이동은 타일 비용만큼 AP를 소비한다.
- 기본 1손 무기 공격은 4 AP.
- 기본 2손 무기 공격은 6 AP.
- 일부 스킬은 3, 4, 5, 6, 9 AP처럼 개별 비용을 가진다.
- AP가 부족하면 해당 행동을 할 수 없다.
- 피로도가 최대치에 도달하면 이동/공격을 할 수 없다.
- 턴 시작 시 피로도 15 회복.

현재 변경점:

- `CombatUnit.has_acted` 중심 구조를 `action_points`, `fatigue` 중심 구조로 변경한다.
- 한 턴에 이동 후 공격, 공격 후 이동, 스킬 여러 번 사용이 가능해야 한다.
- `end_turn()`은 플레이어가 직접 누르거나 AI가 행동을 마쳤을 때만 호출된다.

### 3. 이니셔티브와 턴 순서

각 라운드는 현재 이니셔티브가 높은 순서대로 진행한다.

목표 규칙:

- 라운드 시작 시 살아 있는 모든 유닛의 턴 순서를 다시 계산한다.
- 현재 이니셔티브는 기본 이니셔티브에서 누적 피로도와 장비 피로도 패널티를 반영한다.
- 피로도가 많이 쌓인 유닛은 다음 라운드 순서가 뒤로 밀릴 수 있다.
- `대기`는 현재 라운드 내에서 뒤쪽 순서로 이동한다.
- 도망 상태 유닛은 턴 순서에서 매우 뒤로 밀린다.

구현 위치:

- `CombatState._build_turn_order()` 추가.
- `CombatUnit.get_current_initiative()` 추가.
- `wait_turn()`은 현재 라운드 내 재배치 규칙으로 다시 작성한다.

### 4. Zone of Control

근접 전투 가능 유닛은 인접 타일에 ZoC를 만든다.

목표 규칙:

- 적 ZoC 안에 있는 타일에서 벗어나면 이탈 공격을 받는다.
- 이탈 공격이 모두 빗나가면 이동 성공.
- 하나라도 명중하면 이동 실패.
- 원거리 무기만 든 유닛, 도망/기절/수면 상태 유닛은 ZoC를 만들지 않는다.
- Footwork 같은 특수 스킬은 ZoC 이탈 공격을 무시한다.

초기 구현 범위:

- 1단계: ZoC 표시와 이동 금지/경고.
- 2단계: 이탈 공격 판정.
- 3단계: ZoC 무시 스킬 구현.

구현 위치:

- `CombatRules.get_zoc_cells(unit, board)`.
- `CombatRules.get_hostile_zoc_controllers(unit, cell, all_units, board)`.
- `CombatState.move_unit()`에서 경로의 각 스텝마다 ZoC 이탈 검사.

### 5. 명중률

명중률은 공격자의 스킬과 방어자의 방어를 중심으로 계산한다.

기본 공식:

```text
명중률 = 공격 스킬 - 방어
```

목표 규칙:

- 근접 공격은 `melee_skill`과 `melee_defense`를 사용한다.
- 원거리 공격은 `ranged_skill`과 `ranged_defense`를 사용한다.
- 방어가 50을 초과하면 초과분은 절반 효율로 계산한다.
- 둘러싸임은 방어자의 근접 방어를 낮춘다.
- 고지대 공격은 보너스, 저지대 공격은 패널티를 받는다.
- 사기 상태는 관련 능력치에 배율로 적용된다.
- 일반 공격 명중률은 5% 이상, 95% 이하로 제한한다.
- 명중 판정은 1-100 난수로 한다.
- 명중 후 머리/몸 판정을 별도로 굴린다.

구현 위치:

- `CombatRules.calculate_hit_chance(attacker, defender, skill, context)`.
- `CombatRules.roll_hit(rng, chance)`.
- `CombatRules.roll_body_part(attacker, skill, rng)`.

### 6. 피해와 방어구

피해는 방어구 피해와 HP 피해를 분리해서 계산한다.

목표 규칙:

- 무기/스킬은 기본 피해 범위, 방어구 피해 비율, 방어 관통 비율을 가진다.
- 방어구 피해는 머리/몸 중 맞은 부위의 방어구에 먼저 적용된다.
- HP 피해는 방어 관통 피해에서 남은 방어구의 일부를 차감한다.
- 방어구가 파괴되면 남은 피해 일부가 HP 피해로 추가될 수 있다.
- 머리 명중은 HP 피해에 치명타 배율을 적용한다.
- HP가 0이 되면 사망 처리한다.

초기 단순화:

- 1단계에서는 머리/몸 방어구를 분리하되 부상, 출혈, 중독은 제외한다.
- 2단계에서 상태 이상과 부상을 추가한다.

구현 위치:

- `CombatRules.roll_damage(attacker, defender, skill, body_part, rng)`.
- `CombatRules.apply_damage(defender, damage_result)`.
- `CombatUnit.head_armor`, `body_armor`, `hp`를 실제 전투 피해에 사용.

### 7. 사기

사기는 전투 중 능력치와 통제 가능 여부에 영향을 준다.

목표 상태:

- `confident`
- `steady`
- `wavering`
- `breaking`
- `fleeing`
- `unbreakable`

목표 규칙:

- 기본 상태는 `steady`.
- 좋은 사기는 공격/방어/결의 등에 보너스를 준다.
- 나쁜 사기는 관련 능력치를 낮춘다.
- `fleeing` 유닛은 플레이어가 조작할 수 없고 전투에서 도망가려 한다.
- 언데드형 적은 `unbreakable`로 사기가 변하지 않는다.
- 아군 사망, 적 사망, 큰 피해, 포위, 라운드 시작 시 사기 체크를 수행한다.

초기 구현 범위:

- 1단계: 상태와 능력치 배율만 구현.
- 2단계: 사망/피해 이벤트에 따른 사기 체크.
- 3단계: 도망 AI와 Rally 계열 스킬.

### 8. 스킬과 무기

공격은 "유닛이 공격한다"가 아니라 "장비/스킬을 사용한다"로 처리한다.

필수 데이터:

- `CombatSkillData`: id, 표시명, AP 비용, 피로도 비용, 사거리, 명중 보정, 피해 배율,
  방어구 피해율, 관통률, 머리 명중 보정, 특수 태그.
- `WeaponData`: id, 무기 타입, 피해 범위, 방어구 피해율, 관통률, 내구도, 사용 가능한 스킬.
- `ArmorData`: id, 머리/몸 구분, 방어도, 피로도 패널티.
- `ShieldData`: id, 근접 방어, 원거리 방어, 내구도, 사용 가능한 스킬.

초기 스킬:

- 기본 베기/찌르기/타격 중 하나.
- 방패벽.
- 대기.
- 회복.
- 발놀림.

원작 고유명사는 사용하지 않고 프로젝트 고유 명칭을 붙인다.

### 9. AI

초기 AI 목표:

- 공격 가능한 대상이 있으면 가장 명중률이 높은 공격을 선택한다.
- 공격 불가이면 가장 가까운 적에게 접근한다.
- ZoC 이탈 위험이 큰 이동은 피한다.
- HP가 낮고 사기가 낮으면 후퇴를 고려한다.
- 원거리 유닛은 사거리와 시야를 고려해 위치를 잡는다.

구현 순서:

1. 인접 공격 우선 AI.
2. 최단 경로 접근 AI.
3. AP 기반 이동 후 공격 판단.
4. 원거리 공격과 시야.
5. 사기/후퇴 판단.

## 위키 기준 추가 누락 항목

아래 항목은 현재 계획에 일부만 있거나 아직 충분히 문서화되지 않은 전투 관련
시스템이다. Battle Brothers식 전투를 가깝게 재현하려면 전투 핵심 구현 이후 단계별로
문서와 코드를 추가해야 한다.

### 1. 원거리 전투 세부 규칙

현재 문서에는 원거리 명중률의 큰 방향만 있다. 아래 세부 규칙이 추가로 필요하다.

- 스킬별 거리 명중률 감소.
- 활/석궁/투척/화기 계열의 서로 다른 거리 패널티.
- 첫 번째 헥스를 거리 패널티에서 제외하는 무기와 제외하지 않는 무기 구분.
- 사격선 차단.
- 엄폐/커버로 인한 명중률 감소.
- 빗나간 원거리 공격의 산탄/흩어짐 처리.
- 의도하지 않은 대상 명중.
- 원거리 공격이 아군에게 맞는 경우.
- 야간 전투의 원거리 스킬/방어/시야 패널티.
- 고도에 따른 원거리 최대 사거리 증가.
- 탄약 소모와 전투 후 자동 보충.

필요 데이터:

```gdscript
class_name RangedAttackProfile

var base_range: int = 1
var distance_penalty_per_tile: int = 0
var ignore_first_tile_for_distance: bool = true
var can_scatter: bool = false
var can_hit_friendly: bool = true
var cover_penalty_percent: int = 75
var ammo_cost: int = 1
```

### 2. 상태 이상

현재 문서의 상태는 사기 중심이다. 실제 전투에는 별도 상태 이상 시스템이 필요하다.

우선 등록할 상태 범위:

- `stunned`: 행동 불가 또는 제한.
- `bleeding`: 턴 종료/시작 시 방어구를 무시하는 지속 피해.
- `poisoned`: 지속 피해 또는 능력치 약화.
- `netted`: 이동과 방어 관련 제한.
- `rooted`: 이동 불가.
- `sleeping`: 행동 불가, ZoC 상실.
- `charmed`: 조작권 상실 또는 적대 관계 변화.
- `hexed`: 받은 피해를 연결 대상에게 전달.
- `overwhelmed`: 누적 명중/방어 관련 약화.
- `shieldwall`: 방패 방어 강화.
- `spearwall`: 접근 차단 반격 상태.
- `riposte`: 근접 공격에 대한 반격 상태.
- `indomitable`: 피해 감소와 제어 면역.
- `adrenaline`: 다음 라운드 턴 순서 보정.
- `hidden`: 대상 지정 불가.
- `on_fire`: 타일 또는 유닛 화염 피해.

필요 데이터:

```gdscript
class_name CombatStatusEffectData

var id: String = ""
var duration_turns: int = 0
var stack_mode: String = "refresh"
var stat_modifiers: Dictionary = {}
var blocks_movement: bool = false
var blocks_skills: bool = false
var disables_zoc: bool = false
var damage_over_time: Dictionary = {}
var removed_after_combat: bool = true
```

### 3. 부상

현재 문서에는 부상을 비범위에 가깝게 다뤘다. 하지만 전투 체감에는 부상이 중요하다.

필요 규칙:

- HP 피해가 일정 임계값을 넘으면 임시 부상을 판정한다.
- 일부 부상은 전투 중 능력치를 낮춘다.
- 일부 부상은 출혈 같은 지속 피해를 유발한다.
- 치명타와 큰 피해는 부상 확률을 높인다.
- 일부 적은 부상 면역 또는 높은 HP로 부상 발생이 어렵다.
- 사망하지 않고 쓰러진 형제는 영구 부상을 얻을 수 있다.
- 부상은 전투 종료 후 회복 시간 또는 영구 상태로 나뉜다.

필요 데이터:

```gdscript
class_name InjuryData

var id: String = ""
var body_part: String = "body"
var temporary: bool = true
var stat_modifiers: Dictionary = {}
var dot_effect_id: String = ""
var recovery_days_range: Vector2i = Vector2i.ZERO
```

### 4. 무기와 방패 내구도

현재 문서에는 피해 공식은 있지만 장비 내구도 처리가 부족하다.

필요 규칙:

- 무기는 방어구를 맞혔을 때 내구도가 감소한다.
- HP만 맞힌 공격은 무기 내구도를 감소시키지 않는다.
- 광역 공격은 명중한 대상별로 내구도 손실을 따로 계산한다.
- 활/석궁은 발사할 때 내구도를 소모한다.
- 방패는 원거리 투사체, 방패 파괴 스킬, 방패에 맞은 근접 공격으로 내구도가 감소한다.
- 방패 내구도가 0이 되면 방패 보너스와 방패 스킬이 사라진다.
- Shield Expert 계열 특성은 방패 피해를 줄인다.
- Axe Mastery 계열 특성은 방패 파괴 피해를 늘린다.

필요 데이터:

```gdscript
class_name EquipmentDurabilityData

var max_durability: int = 0
var current_durability: int = 0
var broken: bool = false
```

### 5. 방패 세부 규칙

현재 문서에는 방패벽 정도만 있다. 실제 전투에는 방패 방어와 방패 타격 처리가
필요하다.

필요 규칙:

- 방패는 근접 방어와 원거리 방어를 각각 올린다.
- Shieldwall은 방패 방어 보너스를 증폭한다.
- 인접한 아군 Shieldwall은 추가 보너스를 줄 수 있다.
- 일부 스킬은 방패 방어 보너스를 무시한다.
- 공격이 빗나갔지만 방패에 맞는 결과를 별도로 처리한다.
- Split Shield 계열 스킬은 유닛이 아니라 방패 내구도를 직접 공격한다.

### 6. 특성, 퍽, 숙련

현재 문서는 데이터 구조만 있고 전투 효과의 범위가 부족하다.

필수 전투 영향 범위:

- 능력치 가산 보너스.
- 능력치 배율 보너스.
- 이동 AP/피로도 변경.
- 고도 변경 패널티 제거.
- ZoC 무시.
- 방패/무기 내구도 피해 변경.
- 부상 임계값 변경.
- 상태 이상 면역.
- 사기 체크 보정.
- 머리 명중률 변경.
- 치명 피해 변경.
- 무기 계열별 스킬 AP/피로도/명중률 변경.

처리 방식:

- 모든 전투 계산은 `CombatModifierContext`를 통해 특성/퍽/상태/장비 보정을 합산한다.
- 스킬별 예외 규칙을 `if skill_id == ...`로 흩뿌리지 않고 태그 기반으로 처리한다.

### 7. 특수 스킬과 무기별 공격 패턴

현재 문서에는 기본 공격과 일부 스킬만 있다. 아래 패턴을 데이터화해야 한다.

- 1타 단일 대상 공격.
- 2타 공격.
- 머리 우선/몸 우선 공격.
- 직선 2칸 관통 공격.
- 부채꼴/원형 광역 공격.
- 밀치기/당기기/위치 교환.
- 기절/무장해제/그물/넘어뜨림.
- 방패 파괴.
- 방어구 파괴 전용 공격.
- 방어구 무시 공격.
- 반격 준비.
- 접근 차단 상태.
- 회복/사기 회복.
- 소환/부활.

필요 데이터:

```gdscript
class_name SkillTargetPatternData

var target_type: String = "unit"
var range_min: int = 1
var range_max: int = 1
var area_shape: String = "single"
var requires_line_of_fire: bool = false
var allows_friendly_fire: bool = false
var ignores_zoc: bool = false
```

### 8. 시야, 안개, 은신

현재 고도 섹션에 시야 이점만 있다. 별도 시야 시스템이 필요하다.

필요 규칙:

- 유닛별 기본 시야.
- 고도에 따른 시야 증가.
- 밤의 시야 감소.
- 장애물과 지형의 시야 차단.
- 은신 유닛 대상 지정 제한.
- 원거리 공격의 사격선 판정과 시야 판정 분리.

### 9. 전투 보상과 사후 처리

전투 씬의 종료 조건만 있고 전투 후 처리가 부족하다.

필요 규칙:

- 사망/부상/영구 부상 반영.
- XP 지급.
- 전리품 생성.
- 탄약/소모품 보충.
- 장비 내구도 유지 또는 파손 반영.
- 형제 사기/기분 변화.
- 도망친 유닛 처리.
- 계약/월드 상태에 결과 전달.

### 10. 난이도와 진영 보정

현재 문서에는 난이도 보정이 없다.

필요 규칙:

- 전투 난이도에 따른 명중 굴림 보정.
- 경제 난이도에 따른 탄약 보유량 같은 캠페인 자원 보정.
- 적 조우 규모와 티어 보정.
- 플레이어/적 진영별 예외 규칙을 데이터로 분리.

### 11. 전투 로그와 예측 UI

현재 문서에는 로그가 있지만 결과 설명 기준이 부족하다.

필수 표시:

- 명중률 구성 요소.
- 굴림 값.
- 머리/몸 명중.
- 방어구 피해.
- HP 피해.
- 부상 발생.
- 상태 이상 적용/해제.
- 사기 체크 성공/실패.
- ZoC 이탈 공격.
- 방패 명중/파괴.
- 원거리 빗나감/흩어짐/아군 오발.
- 장비 내구도 변화.

## 전투 화면 목표

`CombatScreen`은 아래 정보를 즉시 읽을 수 있어야 한다.

- 현재 라운드.
- 현재 행동 유닛.
- 턴 순서.
- 선택한 유닛의 HP, 머리 방어구, 몸 방어구, AP, 피로도, 사기.
- 이동 가능 타일.
- 경로와 경로 비용.
- 공격 가능 대상.
- 선택한 스킬의 명중률.
- 예상 피해 범위.
- ZoC 위험 타일.
- 전투 로그.
- 승리/패배 결과.

입력 흐름:

1. 현재 행동 유닛 자동 선택.
2. 스킬 선택 또는 기본 이동 모드.
3. 타일 호버 시 경로, AP 비용, 피로도 비용 표시.
4. 대상 호버 시 명중률과 예상 피해 표시.
5. 클릭으로 이동/공격 실행.
6. AP가 남으면 계속 행동 가능.
7. 턴 종료 버튼으로 다음 유닛 진행.

## 우선순위와 일정

일정 기준:

- 기준일은 KST `2026-06-09`이다.
- 전투 씬 1차 완성까지 16주를 잡는다.
- 기준 인력은 1인 개발이다.
- 새 `.tscn` 파일은 만들지 않는다. 기존 `test/manual/test_combat.tscn`은 수동
  검증용으로만 사용한다.
- 아트, 사운드, 월드맵, 경제, 계약, 이벤트는 일정에서 제외한다.
- 매주 마지막 날에는 GUT 테스트와 수동 전투 3판을 통과해야 한다.

우선순위 등급:

- `P0`: 전투가 성립하기 위한 필수 규칙. 이 단계가 깨지면 다음 단계로 가지 않는다.
- `P1`: Battle Brothers식 체감을 만드는 핵심 규칙.
- `P2`: 전투 깊이를 늘리는 확장 규칙.
- `P3`: 콘텐츠량, 편의성, 장기 polish.

### 마일스톤 요약

| 기간 | 마일스톤 | 우선순위 | 상태 | 산출물/남은 일 |
| --- | --- | --- | --- | --- |
| 2026-06-09 - 2026-06-22 | M1. 전투 도메인 재정비 | P0 | 완료 | AP/피로도/턴/고도/지형 기반 규칙 |
| 2026-06-23 - 2026-07-06 | M2. 명중률과 피해 공식 | P0 | 완료 | 스킬/무기 데이터, 명중, 방어구/HP 피해 |
| 2026-07-07 - 2026-07-20 | M3. 전투 화면 1차 플레이 가능 | P0 | 완료 | 이동/공격/예측 UI/로그/승패. 반복 수동 QA는 M8로 이관 |
| 2026-07-21 - 2026-08-03 | M4. ZoC와 이니셔티브 완성 | P1 | 완료 | 이탈 공격, 대기, 회복, 라운드 순서 재계산. `adrenaline`은 후순위 |
| 2026-08-04 - 2026-08-17 | M5. 원거리와 시야 | P1 | 부분완료 | 사격선, 거리 패널티, 탄약, 고도 사거리 완료. 엄폐/산탄/오발/시야/야간 남음 |
| 2026-08-18 - 2026-08-31 | M6. 사기, 상태 이상, 부상 | P1 | 부분완료 | 사기 체크와 기절/출혈/그물/방패벽 완료. `fleeing`, 부상, 사기 배율 남음 |
| 2026-09-01 - 2026-09-14 | M7. AI와 적 로스터 1차 | P1 | 1차 완료 | 산적/언데드/야수 조우와 AP 기반 AI 완료. AI 프로필/HP 위험/지원 AI 남음 |
| 2026-09-15 - 2026-09-28 | M8. 안정화와 전투 알파 | P0/P1 | 다음 우선순위 | 수동 반복 검증, 로그/상태 QA, seed 재현 문서화 |

### M1. 전투 도메인 재정비

기간: `2026-06-09 - 2026-06-22`

목표:

- 현재 단순 이동/공격 구조를 AP/피로도/지형/고도 기반 구조로 바꾼다.
- `CombatRules`가 모든 계산의 단일 진입점이 되게 한다.
- `CombatScreen`은 규칙을 직접 계산하지 않고 `CombatState`와 `CombatRules` 결과만
  표시한다.

작업:

- `CombatTileData` 추가.
- `CombatBoard`에 `terrain_by_cell`, `height_by_cell` 추가.
- `CombatBoard.setup()`을 타일 데이터 입력도 받을 수 있게 확장.
- `CombatRules.get_step_ap_cost()` 추가.
- `CombatRules.get_step_fatigue_cost()` 추가.
- `CombatRules.get_path_cost()` 추가.
- `CombatRules.get_legal_moves()`를 `MOVE_RANGE`가 아닌 AP/피로도 기반으로 변경.
- `CombatUnit`의 `action_points`, `max_action_points`, `fatigue`, `max_fatigue`를
  실제 행동 소비에 연결.
- `CombatState.start_turn()` 추가.
- `CombatState.end_turn()`에서 다음 유닛 AP 초기화와 피로도 회복 처리.
- 기존 `has_acted`는 제거하거나 `turn_done` 보조 플래그로 축소.

테스트:

- 같은 높이 평지 이동 AP 비용.
- 거친 지형/늪 이동 AP 비용.
- 고도 변경 AP 추가 비용.
- 고도 변경 피로도 추가 비용.
- AP 부족 시 이동 불가.
- 피로도 한계 초과 시 이동 불가.
- 턴 시작 AP 회복.
- 턴 시작 피로도 회복.

완료 기준:

- 한 유닛이 한 턴 안에 여러 칸 이동하고 AP가 남으면 계속 행동할 수 있다.
- `MOVE_RANGE` 상수 없이 이동 가능 셀이 계산된다.
- 수동 전투에서 AP와 피로도 값이 실제 행동 후 변한다.

### M2. 명중률과 피해 공식

기간: `2026-06-23 - 2026-07-06`

목표:

- 공격을 "유닛 기본 공격"이 아니라 "스킬 사용"으로 바꾼다.
- Battle Brothers식 명중률, 머리/몸 명중, 방어구/HP 피해를 구현한다.

작업:

- `CombatSkillData` 추가.
- `WeaponData`, `ArmorData`, `ShieldData` 추가 또는 기존 `Item`과 명확히 분리.
- `CombatSkillRegistry` 추가.
- `EquipmentRegistry` 추가.
- 기본 1손 근접 스킬 1개, 창 스킬 1개, 둔기 스킬 1개, 기본 원거리 스킬 1개 등록.
- `CombatRules.calculate_hit_chance()` 추가.
- 방어 50 초과 효율 반감 추가.
- 명중률 5-95 클램프 추가.
- 고도 명중 보정 추가.
- 둘러싸임 근접 방어 패널티 추가.
- `CombatRules.roll_body_part()` 추가.
- `CombatRules.roll_damage()` 추가.
- `CombatRules.apply_damage()`에서 머리/몸 방어구와 HP 피해 분리.
- `CombatActionResult` 딕셔너리 형식을 고정한다.

테스트:

- 명중률 기본 공식.
- 방어 50 초과 효율 반감.
- 5-95 클램프.
- 고지대 명중 보너스.
- 저지대 명중 패널티.
- 고정 seed 명중 결과.
- 머리/몸 판정.
- 방어구 피해와 HP 피해 분리.
- 사망 시 점유 셀 해제.

완료 기준:

- 같은 seed와 같은 입력이면 공격 결과가 항상 같다.
- 전투 로그에 명중률, 굴림, 맞은 부위, 방어구 피해, HP 피해가 나온다.
- 방어구가 있는 유닛과 없는 유닛의 생존성이 명확히 다르다.

### M3. 전투 화면 1차 플레이 가능

기간: `2026-07-07 - 2026-07-20`

목표:

- 테스트용 전투가 "전술 게임처럼" 플레이 가능해야 한다.
- 플레이어는 행동 전에 결과를 예측할 수 있어야 한다.

작업:

- 현재 행동 유닛 자동 선택.
- AP/피로도/머리 방어구/몸 방어구/HP/사기 표시.
- 타일 호버 시 경로, AP 비용, 피로도 비용 표시.
- 공격 대상 호버 시 명중률과 예상 피해 표시.
- 스킬 버튼 영역 추가.
- 현재 선택 스킬의 사거리/대상 표시.
- 턴 순서 UI를 실제 `CombatState` 순서와 연결.
- 전투 로그를 여러 줄 누적 구조로 변경.
- 결과 팝업의 승리/패배 흐름 정리.

테스트:

- UI 표시값과 실제 `CombatUnit` 값 일치.
- 이동 예측 비용과 실제 소비 비용 일치.
- 공격 예측 명중률과 실제 계산 명중률 일치.
- 유닛 사망 후 UI에서 제거.
- 승리/패배 팝업 노출.

수동 검증:

- `test/manual/test_combat.tscn`에서 플레이어가 이동, 공격, 턴 종료, 승리까지 진행.
- 같은 seed 전투를 2회 실행했을 때 주요 결과가 같다.

완료 기준:

- 개발자가 룰을 몰라도 화면만 보고 가능한 행동을 이해할 수 있다.
- 이동/공격/턴 종료/승패까지 한 판이 끊기지 않는다.

현재 진행상황:

- 상태: 완료.
- 구현 완료: 활성 유닛 자동 선택, AP/피로도/HP/사기/머리 방어구/몸 방어구 표시,
  이동/공격 호버 예측, 스킬 버튼, 턴 순서 UI, 누적 전투 로그, 승리/패배 흐름.
- 테스트 상태: `gdlint` 통과, GUT 131개 통과.
- 남은 일: 수동 반복 플레이와 문구/가독성 QA는 M8 안정화에서 추적한다.

### M4. ZoC와 이니셔티브 완성

기간: `2026-07-21 - 2026-08-03`

목표:

- 근접 압박, 대기, 회복, 라운드 순서가 Battle Brothers식 전술 판단을 만들게 한다.

작업:

- `CombatRules.get_zoc_cells()` 추가.
- `CombatRules.get_hostile_zoc_controllers()` 추가.
- 고도 차이 2 이상이면 ZoC 제외.
- ZoC 이탈 공격 추가.
- 이탈 공격 명중 시 이동 중단.
- 이탈 공격 실패 시 이동 계속.
- `wait_turn()` 재작성.
- `recover` 스킬 추가.
- 라운드 시작 시 현재 이니셔티브로 턴 순서 재계산.
- 피로도에 따른 현재 이니셔티브 계산.
- `adrenaline` 상태의 턴 순서 보정 기반 마련.

테스트:

- ZoC 셀 계산.
- 고도 차이 2 이상 ZoC 없음.
- 이탈 공격 성공 시 이동 실패.
- 이탈 공격 실패 시 이동 성공.
- 대기와 턴 종료의 순서 차이.
- 피로도 증가 후 다음 라운드 이니셔티브 하락.
- 회복으로 피로도 감소.

완료 기준:

- 적 옆에서 빠져나가는 선택이 전술적 위험으로 작동한다.
- 피로도가 쌓인 유닛은 다음 라운드 순서가 늦어진다.

현재 진행상황:

- 상태: 완료.
- 구현 완료: ZoC 셀, 고도 차이 2 이상 ZoC 제외, 이탈 공격 성공/실패, `wait_turn()`,
  `recover`, 피로도 기반 다음 라운드 이니셔티브, `footwork` ZoC 무시 이동.
- 테스트 상태: `gdlint` 통과, GUT 131개 통과.
- 남은 확장: `adrenaline` 기반 턴 순서 보정은 후순위 P1/P2로 남긴다.

### M5. 원거리와 시야

기간: `2026-08-04 - 2026-08-17`

목표:

- 원거리 공격이 단순 장거리 근접 공격이 아니라 별도 규칙으로 작동한다.

작업:

- `RangedAttackProfile` 추가.
- 사거리와 거리 패널티 적용.
- 고도에 따른 최대 사거리 증가.
- 사격선 판정 추가.
- 사격선 차단 타일 처리.
- 엄폐/커버 명중률 패널티 추가.
- 원거리 빗나감 산탄 처리.
- 아군 오발 가능성 처리.
- 탄약 소모 추가.
- 야간 전투 패널티를 데이터 플래그로 추가.
- 시야 범위 계산 추가.

테스트:

- 거리별 명중률 감소.
- 높은 곳에서 낮은 대상으로 사거리 증가.
- 사격선 차단 시 공격 불가 또는 명중률 감소.
- 엄폐 대상 명중률 감소.
- 빗나감 산탄이 seed 기반으로 결정.
- 아군 오발 발생 가능.
- 탄약 부족 시 원거리 공격 불가.

완료 기준:

- 활/석궁/투척형 공격이 서로 다른 거리 체감을 가진다.
- 원거리 유닛이 고지대와 사격선을 고려해야 한다.

현재 진행상황:

- 상태: 부분완료.
- 이번 알파 최소판 완료: `ranged_shot`, `ranged_skill`/`ranged_defense`, 거리 패널티,
  고도 사거리 보너스, 탄약 소모/부족 처리, 차단 타일 사격선 판정, 원거리 AI 공격.
- 테스트 상태: `gdlint` 통과, GUT 131개 통과.
- 남은 확장: `RangedAttackProfile` 별도 타입, 엄폐/커버, 빗나감 산탄, 아군 오발,
  야간 패널티, 별도 시야/안개 계산.

### M6. 사기, 상태 이상, 부상

기간: `2026-08-18 - 2026-08-31`

목표:

- 피해 결과가 HP 감소에서 끝나지 않고, 전투 상태와 다음 판단에 영향을 주게 한다.

작업:

- `MoraleState` enum 또는 문자열 상수 정리.
- 사기별 능력치 배율 적용.
- 사망/큰 피해/포위 이벤트 사기 체크.
- `fleeing` 조작 제한과 도망 AI.
- `CombatStatusEffectData` 추가.
- 기절, 출혈, 그물, 방패벽, 창벽, 반격, 불굴 우선 구현.
- 상태 적용/갱신/해제 라이프사이클 추가.
- `InjuryData` 추가.
- 임시 부상 판정 추가.
- 부상별 능력치 패널티 추가.

테스트:

- 사기 상태별 능력치 보정.
- 적 사망 시 주변 유닛 사기 체크.
- 큰 피해 시 사기 체크.
- `fleeing` 유닛 조작 제한.
- 기절 유닛 행동 불가.
- 출혈 지속 피해.
- 그물 이동 제한.
- 임시 부상 능력치 감소.

완료 기준:

- 전투 중 유닛 상태가 행동 선택을 바꾼다.
- 로그에서 사기/상태/부상 발생 원인을 추적할 수 있다.

현재 진행상황:

- 상태: 부분완료.
- 이번 알파 최소판 완료: `MoraleState`, 큰 피해/아군 사망 사기 체크, 기절/출혈/그물/
  방패벽 상태 데이터, 상태 적용/만료, 행동/이동 제한, 출혈 시작 턴 피해.
- 테스트 상태: `gdlint` 통과, GUT 131개 통과.
- 남은 확장: `fleeing` 조작 제한과 도망 AI, 사기 상태별 능력치 배율, 창벽/반격/불굴,
  `InjuryData`, 임시 부상 판정과 능력치 패널티.

### M7. AI와 적 로스터 1차

기간: `2026-09-01 - 2026-09-14`

목표:

- 적이 최소한의 전술적 판단을 한다.
- 전투 검증용 적 로스터를 하드코딩 2명에서 파벌 기반 데이터로 바꾼다.

작업:

- `EnemyArchetypeData` 추가.
- `EnemyRegistry` 추가.
- 산적 전열/방패/궁수 3종 추가.
- 언데드 기본 근접/부활 지원 2종 추가.
- 야수 근접/고기동 2종 추가.
- `EncounterData` 추가.
- 조우 생성기를 seed 기반으로 작성.
- AI 프로필 추가: `melee_basic`, `ranged_basic`, `support_basic`, `beast_basic`.
- AI 행동 평가: 공격 가능성, 이동 후 공격 가능성, ZoC 위험, HP 위험.
- AI가 AP를 모두 쓰거나 의미 있는 행동이 없으면 턴 종료.

테스트:

- 적 archetype 필수 필드 검사.
- 파벌별 최소 1종 이상 등록 검사.
- 같은 seed 조우 생성 결과 동일.
- AI가 인접 대상 공격.
- AI가 이동 후 공격.
- AI가 명백히 위험한 ZoC 이탈을 피함.
- 원거리 AI가 사거리 안에서 공격.

완료 기준:

- 산적, 언데드, 야수 기본 조우를 각각 1판씩 플레이할 수 있다.
- AI 턴이 무한 루프 없이 종료된다.

현재 진행상황:

- 상태: 1차 완료.
- 구현 완료: `EnemyArchetypeData`, `EnemyRegistry`, `EncounterData`, `EncounterRegistry`,
  산적 3종, 언데드 2종, 야수 2종, 산적/언데드/야수 기본 조우, Explore/수동 전투 진입
  경로의 `encounter_id` 연결.
- 구현 완료: `CombatAi`가 공격 가능성, 이동 후 공격 가능성, ZoC 위험, 원거리 사거리를
  평가하고 화면 AI 턴은 선택 결과를 실행한다.
- 테스트 상태: `gdlint` 통과, GUT 131개 통과.
- 남은 확장: 명시적 AI 프로필(`melee_basic`, `ranged_basic`, `support_basic`,
  `beast_basic`), HP 위험 평가, 지원형 AI, seed 기반 조우 변형 생성.

### M8. 안정화와 전투 알파

기간: `2026-09-15 - 2026-09-28`

목표:

- 전투 씬을 알파 기준으로 잠근다.
- 이후 콘텐츠 확장 전에 규칙 회귀를 잡는다.

작업:

- 우선순위 1: 수동 전투 체크리스트 실행 및 결과 기록.
- 우선순위 2: 산적/언데드/야수 조우를 각각 반복 플레이.
- 우선순위 3: 전투 로그 문구, 상태 표시, 예측 UI 가독성 QA.
- 우선순위 4: 같은 seed 전투 재현 절차 문서화.
- 우선순위 5: 남은 P1 확장 후보를 `fleeing`, 부상, 시야/안개, 엄폐/오발,
  전투 후 XP/전리품 순서로 재정렬.
- 성능 확인: 20대20 전투에서 입력 지연과 AI 턴 시간 측정.

현재 진행상황:

- 상태: 안정화 진행 중.
- 자동 검증 기준: `gdlint` 통과, GUT 141개 통과.
- 코드 기준: M1-M4 완료, M5-M6 알파 최소판 완료, M7 1차 완료.
- 완료: 자동 조우 smoke 테스트로 산적/언데드/야수 조우가 turn cap 안에서 종료되는지
  검증한다.
- 완료: 산적/언데드/야수 조우는 같은 seed에서 주요 턴/공격 이벤트 순서가 재현되는지
  검증한다.
- 완료: Explore의 성채/폐허/거미 숲 조우 매핑과 Combat 진입 데이터 복원을 자동 테스트로
  검증한다.
- 완료: 유닛 정보 UI가 HP/AP/피로도/머리 방어구/몸 방어구/사기/상태 효과를 함께
  표시하도록 고정한다.
- 완료: 공격 로그, 빗나감 로그, 사기 체크 로그, 공격 예측 UI가 핵심 결과 필드를
  표시하도록 포맷 테스트로 고정한다.
- 남은 알파 잠금 작업은 구현보다 수동 반복 검증과 문서화가 중심이다.

알파 완료 기준:

- 산적 조우, 언데드 조우, 야수 조우를 각각 3회씩 끝까지 진행할 수 있다.
- 모든 전투가 승리/패배/도망 중 하나로 종료된다.
- 같은 seed의 같은 조우는 같은 결과 순서를 재현한다.
- GUT 전체 테스트가 통과한다.
- 전투 화면에서 AP, 피로도, 사기, 방어구, 명중률, 예상 피해, 로그가 모두 표시된다.
- 알려진 P0 버그가 없다.

## 상세 백로그

### P0 백로그

- 완료: `CombatUnit` 전투 스탯 정리.
- 완료: `CombatTileData` 추가.
- 완료: AP 기반 이동과 공격.
- 완료: 피로도 소비와 회복.
- 완료: 턴 시작/종료 라이프사이클.
- 완료: 명중률과 피해 계산.
- 완료: 머리/몸 방어구와 HP 피해 분리.
- 완료: 스킬/무기 최소 데이터.
- 완료: 결정론적 RNG.
- 완료: 승리/패배 판정.
- 완료: 전투 UI 필수 정보 표시.
- 완료: GUT 회귀 테스트.

### P1 백로그

- 완료: 고도 명중/사거리/근접 제한.
- 완료: ZoC와 이탈 공격.
- 완료: 이니셔티브 재계산.
- 완료: 대기와 회복.
- 완료: 원거리 사격선.
- 완료: 탄약.
- 완료: 사기 체크.
- 완료: 핵심 상태 이상(`stunned`, `bleeding`, `netted`, `shieldwall`).
- 완료: AP 기반 AI.
- 완료: 산적/언데드/야수 기본 적과 조우.
- 남음: `fleeing`과 도망 AI.
- 남음: 임시 부상과 부상별 능력치 패널티.
- 남음: 별도 시야/안개 시스템.
- 남음: 엄폐, 산탄, 아군 오발.
- 남음: AI 프로필, HP 위험 평가, 지원형 AI.

### P2 백로그

- 방패 명중과 방패 내구도.
- 무기 내구도.
- 산탄/아군 오발 고도화.
- 특성/퍽/숙련 전체 보정.
- 챔피언 변형.
- 추가 인간계/그린스킨 적.
- 전투 후 XP/전리품/부상 반영.

### P3 백로그

- 전체 형제단 배경 등록.
- 전체 적 로스터 등록.
- 전설 조우.
- 애니메이션 polish.
- 사운드.
- 고급 로그 필터.
- 전투 리플레이/디버그 seed UI.

## 테스트 계획

자동 테스트는 기능이 들어가는 같은 PR 또는 같은 작업 단위에 추가한다.

단위 테스트:

- 타일 이동 비용 계산.
- AP 부족 시 이동/공격 실패.
- 피로도 최대치 도달 시 행동 실패.
- 라운드 시작 AP 회복과 피로도 회복.
- 이니셔티브 기반 턴 순서.
- 방어 50 초과 효율 반감.
- 명중률 5-95 제한.
- 고정 seed 공격 결과.
- 머리/몸 방어구 피해 분리.
- 사망 시 점유 셀 해제와 턴 순서 제거.
- ZoC 이탈 공격 성공/실패.
- 고도 차이 2 이상 근접 공격 불가.
- 고도 차이 2 이상 ZoC 없음.
- 원거리 사거리/거리 패널티.
- 상태 이상 적용/만료.
- 사기 체크.
- 승리/패배 판정.

통합 테스트:

- 완료: 산적 조우 완료.
- 완료: 언데드 조우 완료.
- 완료: 야수 조우 완료.
- 완료: 산적/언데드/야수 조우 같은 seed 2회 재현.
- 유닛 사망 후 턴 순서와 점유 셀 정합성.
- AI 턴 무한 루프 방지.

수동 테스트:

- `test/manual/test_combat.tscn`로 전투 진입.
- 이동 후 공격이 가능한지 확인.
- AP가 남은 상태에서 여러 행동이 가능한지 확인.
- 적 옆에서 이탈할 때 ZoC가 작동하는지 확인.
- 고지대/저지대 명중률이 UI에 반영되는지 확인.
- 방어구가 먼저 깎이고 HP가 늦게 줄어드는지 확인.
- 출혈/기절/그물 같은 상태가 로그와 UI에 표시되는지 확인.
- 같은 seed로 같은 결과가 나오는지 확인.

릴리즈 게이트:

- P0 테스트는 항상 100% 통과해야 한다.
- P1 기능은 구현된 범위 내에서 자동 테스트가 있어야 한다.
- 수동 전투 3판 중 하나라도 중단되면 알파 완료로 보지 않는다.
- UI 예측값과 실제 결과가 다르면 해당 기능은 완료로 보지 않는다.

## 즉시 착수 순서

다음 착수 순서는 M8 안정화와 수동 검증이다.

1. 완료: 자동 smoke 테스트에서 산적/언데드/야수 조우가 각각 turn cap 안에서 종료되는지
   확인한다.
2. 완료: 자동 smoke 테스트에서 산적/언데드/야수 조우 같은 seed 2회 실행의 주요 이벤트
   순서를 비교한다.
3. `test/manual/test_combat.tscn`에서 산적 조우를 3회 진행하고, 승리/패배/중단 여부와
   이상 로그를 기록한다.
4. 완료: 자동 테스트에서 Explore 성채/폐허/거미 숲 매핑과 Combat 적 복원을 확인한다.
5. Explore 화면에서 성채/폐허/거미 숲에 진입해 산적/언데드/야수 조우가 각각 로드되는지
   확인한다.
6. 수동으로 같은 seed의 같은 조우를 2회 반복해 주요 공격 결과와 로그 순서가 재현되는지
   확인한다.
7. 이동 후 공격, AP가 남은 상태의 추가 행동, ZoC 이탈, footwork, recover, shieldwall을
   수동 체크리스트로 확인한다.
8. 원거리 사격선, 탄약 부족, 고도 사거리 보너스, 차단 타일을 수동으로 확인한다.
9. 기절/출혈/그물/방패벽과 사기 체크가 UI와 로그에 이해 가능한 문구로 남는지 확인한다.
10. 수동 QA에서 발견한 P0 버그를 먼저 수정하고, 새 회귀 테스트를 추가한다.
11. 남은 P1 확장 후보는 `fleeing`, 부상, 시야/안개, 엄폐/오발, 전투 후 XP/전리품 순서로
   별도 작업 단위로 분리한다.

M8 완료 기준:

- `gdlint`와 GUT 전체 테스트가 통과한다.
- 산적/언데드/야수 조우가 각각 끝까지 진행된다.
- 같은 seed 조우의 주요 결과가 재현된다.
- 전투 화면만 보고 이동, 공격, 회복, 대기, 스킬 사용, 승패 흐름을 이해할 수 있다.
- 알려진 P0 전투 버그가 없다.

## 비범위

아래 항목은 전투 핵심이 안정된 뒤 진행한다.

- 원작 고유 세력, 인물, 장비명, 퀘스트명 복제.
- 원작 아트 또는 아이콘 복제.
- 완성형 애니메이션.
- 월드맵 계약 시스템.
- 경제, 고용, 상점, 이벤트.
- DLC별 세부 수치 전체 재현.
