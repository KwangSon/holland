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
					"armor": 10,
					"max_ap": 2,
					"initiative": 8,
					"melee_skill": 60,
					"melee_defense": 15,
					"damage_min": 8,
					"damage_max": 16,
					"move_range": 3,
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
					"armor": 4,
					"max_ap": 2,
					"initiative": 6,
					"melee_skill": 45,
					"melee_defense": 10,
					"damage_min": 6,
					"damage_max": 12,
					"move_range": 4,
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
					"armor": 18,
					"max_ap": 2,
					"initiative": 4,
					"melee_skill": 55,
					"melee_defense": 22,
					"damage_min": 7,
					"damage_max": 13,
					"move_range": 2,
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
					"armor": 4,
					"max_ap": 2,
					"initiative": 7,
					"melee_skill": 50,
					"melee_defense": 10,
					"damage_min": 6,
					"damage_max": 14,
					"move_range": 3,
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
					"armor": 12,
					"max_ap": 2,
					"initiative": 5,
					"melee_skill": 55,
					"melee_defense": 14,
					"damage_min": 8,
					"damage_max": 15,
					"move_range": 2,
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
					"armor": 6,
					"max_ap": 2,
					"initiative": 3,
					"melee_skill": 48,
					"melee_defense": 8,
					"damage_min": 7,
					"damage_max": 16,
					"move_range": 3,
				}
			)
		),
	]


static func test_board_seed() -> int:
	return 42
