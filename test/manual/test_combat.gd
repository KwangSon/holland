extends Node2D


func _ready() -> void:
	SaveManager.rna = {
		"party":
		[
			{
				"id": "p1",
				"display_name": "성직자",
				"team": "player",
				"unit_type": CombatUnit.UnitType.PRIEST,
				"sprite_texture": preload("res://asset/sprite/Token-oathbringer-champion.png"),
				"position": Vector2i(1, 3),
				"max_hp": 30,
				"max_fatigue": 90,
				"damage": 10,
				# 장비: Mace + Kettle Hat + Gambeson
				"weapon": Item.mace(),
				"head_armor_item": Item.kettle_hat(),
				"body_armor_item": Item.gambeson(),
			},
			{
				"id": "p2",
				"display_name": "해부학자",
				"team": "player",
				"unit_type": CombatUnit.UnitType.ANATOMIST,
				"sprite_texture": preload("res://asset/sprite/Token-gladiator-champion.png"),
				"position": Vector2i(1, 4),
				"max_hp": 35,
				"max_fatigue": 100,
				"damage": 12,
				# 장비: Longsword + Nasal Helm + Chainmail Hauberk
				"weapon": Item.longsword(),
				"head_armor_item": Item.nasal_helm(),
				"body_armor_item": Item.chainmail_hauberk(),
			},
			{
				"id": "p3",
				"display_name": "궁수",
				"team": "player",
				"unit_type": CombatUnit.UnitType.BOWYER,
				"sprite_texture": preload("res://asset/sprite/Token-gunner.png"),
				"position": Vector2i(2, 3),
				"max_hp": 25,
				"max_fatigue": 80,
				"damage": 11,
				"is_ai": true,
				# 장비: Crossbow + Sallet + Ranger's Boots
				"weapon": Item.crossbow(),
				"head_armor_item": Item.sallet(),
				"accessory": Item.rangers_boots(),
			},
		],
		"encounter":
		{
			"enemies":
			[
				{
					"id": "e1",
					"display_name": "고블린 습격자",
					"team": "enemy",
					"unit_type": CombatUnit.UnitType.GOBLIN_AMBUSHER,
					"sprite_texture": preload("res://asset/sprite/Token-orc-berserk.png"),
					"position": Vector2i(7, 3),
					"max_hp": 25,
					"max_fatigue": 80,
					"damage": 10,
					"is_ai": true,
				},
				{
					"id": "e2",
					"display_name": "네크로맨서",
					"team": "enemy",
					"unit_type": CombatUnit.UnitType.NECROMANCER,
					"sprite_texture": preload("res://asset/sprite/Token-orc-warrior-champion.png"),
					"position": Vector2i(6, 4),
					"max_hp": 30,
					"max_fatigue": 100,
					"damage": 12,
					"is_ai": true,
				},
			],
			"seed": 42,
		},
	}
	ScreenManager.change_screen(ScreenManager.Screen.COMBAT)
