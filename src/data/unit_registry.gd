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
					"head_armor": 15,
					"body_armor": 35,
					"max_action_points": 9,
					"max_fatigue": 90,
					"initiative": 95,
					"melee_skill": 58,
					"ranged_skill": 35,
					"melee_defense": 8,
					"ranged_defense": 6,
					"damage": 10,
					"armor_penetration": 25,
					"chance_to_hit_head": 25,
					"skill_ids": [CombatSkillRegistry.BASIC_ATTACK_ID, CombatSkillRegistry.SHIELDWALL_ID],
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
					"head_armor": 20,
					"body_armor": 40,
					"max_action_points": 9,
					"max_fatigue": 100,
					"initiative": 85,
					"melee_skill": 62,
					"ranged_skill": 30,
					"melee_defense": 10,
					"ranged_defense": 8,
					"damage": 12,
					"armor_penetration": 30,
					"chance_to_hit_head": 25,
					"skill_ids": [CombatSkillRegistry.BASIC_ATTACK_ID, CombatSkillRegistry.MACE_STRIKE_ID],
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
					"head_armor": 10,
					"body_armor": 25,
					"max_action_points": 9,
					"max_fatigue": 80,
					"initiative": 105,
					"melee_skill": 48,
					"ranged_skill": 65,
					"melee_defense": 5,
					"ranged_defense": 10,
					"damage": 11,
					"armor_penetration": 20,
					"chance_to_hit_head": 30,
					"ammo": 12,
					"max_ammo": 12,
					"skill_ids": [CombatSkillRegistry.RANGED_SHOT_ID, CombatSkillRegistry.BASIC_ATTACK_ID],
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
					"head_armor": 8,
					"body_armor": 20,
					"max_action_points": 9,
					"max_fatigue": 80,
					"initiative": 100,
					"melee_skill": 52,
					"ranged_skill": 45,
					"melee_defense": 8,
					"ranged_defense": 8,
					"damage": 10,
					"armor_penetration": 20,
					"chance_to_hit_head": 25,
					"ammo": 8,
					"max_ammo": 8,
					"is_ai": true,
					"skill_ids": [CombatSkillRegistry.RANGED_SHOT_ID, CombatSkillRegistry.BASIC_ATTACK_ID],
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
					"head_armor": 12,
					"body_armor": 28,
					"max_action_points": 9,
					"max_fatigue": 100,
					"initiative": 70,
					"melee_skill": 55,
					"ranged_skill": 55,
					"melee_defense": 6,
					"ranged_defense": 10,
					"damage": 12,
					"armor_penetration": 25,
					"chance_to_hit_head": 25,
					"ammo": 6,
					"max_ammo": 6,
					"is_ai": true,
					"skill_ids": [CombatSkillRegistry.RANGED_SHOT_ID, CombatSkillRegistry.BASIC_ATTACK_ID],
				}
			)
		),
	]


static func test_board_seed() -> int:
	return 42
