class_name UnitRegistry

## Sprite textures - Player
const SPRITE_PRIEST := preload("res://asset/sprite/Token-oathbringer-champion.png")
const SPRITE_ANATOMIST := preload("res://asset/sprite/Token-gladiator-champion.png")
const SPRITE_BOWYER := preload("res://asset/sprite/Token-gunner.png")

## Sprite textures - Enemy
const SPRITE_GOBLIN_AMBUSHER := preload("res://asset/sprite/Token-orc-berserk.png")
const SPRITE_NECROMANCER := preload("res://asset/sprite/Token-orc-warrior-champion.png")


## Player units - 3 types: Priest, Anatomist, Bowyer
static func player_units() -> Array[CombatUnit]:
	return [
		(
			CombatUnit
			. create(
				{
					"id": "p1",
					"display_name": "성직자",
					"team": "player",
					"unit_type": CombatUnit.UnitType.PRIEST,
					"sprite_texture": SPRITE_PRIEST,
					"position": Vector2i(1, 3),
					"max_hp": 30,
					"max_fatigue": 90,
					"damage": 10,
				}
			)
		),
		(
			CombatUnit
			. create(
				{
					"id": "p2",
					"display_name": "해부학자",
					"team": "player",
					"unit_type": CombatUnit.UnitType.ANATOMIST,
					"sprite_texture": SPRITE_ANATOMIST,
					"position": Vector2i(2, 4),
					"max_hp": 35,
					"max_fatigue": 100,
					"damage": 12,
				}
			)
		),
		(
			CombatUnit
			. create(
				{
					"id": "p3",
					"display_name": "궁수",
					"team": "player",
					"unit_type": CombatUnit.UnitType.BOWYER,
					"sprite_texture": SPRITE_BOWYER,
					"position": Vector2i(1, 5),
					"max_hp": 25,
					"max_fatigue": 80,
					"damage": 11,
				}
			)
		),
	]


## Enemy units - 2 types: Goblin Ambusher, Necromancer
static func enemy_units() -> Array[CombatUnit]:
	return [
		(
			CombatUnit
			. create(
				{
					"id": "e1",
					"display_name": "고블린 습격자",
					"team": "enemy",
					"unit_type": CombatUnit.UnitType.GOBLIN_AMBUSHER,
					"sprite_texture": SPRITE_GOBLIN_AMBUSHER,
					"position": Vector2i(7, 3),
					"max_hp": 25,
					"max_fatigue": 80,
					"damage": 10,
					"is_ai": true,
				}
			)
		),
		(
			CombatUnit
			. create(
				{
					"id": "e2",
					"display_name": "네크로맨서",
					"team": "enemy",
					"unit_type": CombatUnit.UnitType.NECROMANCER,
					"sprite_texture": SPRITE_NECROMANCER,
					"position": Vector2i(6, 4),
					"max_hp": 30,
					"max_fatigue": 100,
					"damage": 12,
					"is_ai": true,
				}
			)
		),
	]


static func test_board_seed() -> int:
	return 42
