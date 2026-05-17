class_name UnitRegistry


## Player units start on the left side of the test map (cols 1-2, rows 3-5).
static func player_units() -> Array[CombatUnit]:
	return [
		(
			CombatUnit
			. create(
				{
					"id": "p1",
					"display_name": "전사",
					"team": "player",
					"position": Vector2i(1, 3),
					"max_hp": 35,
					"max_fatigue": 100,
					"attack_power": 12,
				}
			)
		),
		(
			CombatUnit
			. create(
				{
					"id": "p2",
					"display_name": "궁수",
					"team": "player",
					"position": Vector2i(2, 4),
					"max_hp": 22,
					"max_fatigue": 80,
					"attack_power": 9,
				}
			)
		),
		(
			CombatUnit
			. create(
				{
					"id": "p3",
					"display_name": "방패병",
					"team": "player",
					"position": Vector2i(1, 5),
					"max_hp": 45,
					"max_fatigue": 120,
					"attack_power": 10,
				}
			)
		),
	]


## Enemy units start on the right side of the test map (cols 6-7, rows 3-5).
static func enemy_units() -> Array[CombatUnit]:
	return [
		(
			CombatUnit
			. create(
				{
					"id": "e1",
					"display_name": "도적",
					"team": "enemy",
					"position": Vector2i(7, 3),
					"max_hp": 22,
					"max_fatigue": 90,
					"attack_power": 10,
				}
			)
		),
		(
			CombatUnit
			. create(
				{
					"id": "e2",
					"display_name": "중갑병",
					"team": "enemy",
					"position": Vector2i(6, 4),
					"max_hp": 30,
					"max_fatigue": 110,
					"attack_power": 11,
				}
			)
		),
		(
			CombatUnit
			. create(
				{
					"id": "e3",
					"display_name": "창병",
					"team": "enemy",
					"position": Vector2i(7, 5),
					"max_hp": 28,
					"max_fatigue": 95,
					"attack_power": 12,
				}
			)
		),
	]


static func test_board_seed() -> int:
	return 42
