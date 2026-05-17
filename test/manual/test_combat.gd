extends Node2D


func _ready() -> void:
	SaveManager.rna = {
		"party":
		[
			{
				"id": "p1",
				"display_name": "기사",
				"team": "player",
				"position": Vector2i(1, 3),
				"max_hp": 60,
				"max_fatigue": 120,
				"attack_power": 15,
			},
			{
				"id": "p2",
				"display_name": "성직자",
				"team": "player",
				"position": Vector2i(1, 4),
				"max_hp": 40,
				"max_fatigue": 100,
				"attack_power": 8,
			},
			{
				"id": "p3",
				"display_name": "궁수",
				"team": "player",
				"position": Vector2i(2, 3),
				"max_hp": 30,
				"max_fatigue": 80,
				"attack_power": 12,
				"is_ai": true,
			},
		],
		"encounter":
		{
			"enemies":
			[
				{
					"id": "e1",
					"display_name": "도적",
					"team": "enemy",
					"position": Vector2i(7, 3),
					"max_hp": 30,
					"max_fatigue": 90,
					"attack_power": 10,
					"is_ai": true,
				},
				{
					"id": "e2",
					"display_name": "중갑병",
					"team": "enemy",
					"position": Vector2i(6, 4),
					"max_hp": 55,
					"max_fatigue": 110,
					"attack_power": 14,
					"is_ai": true,
				},
				{
					"id": "e3",
					"display_name": "창병",
					"team": "enemy",
					"position": Vector2i(7, 5),
					"max_hp": 35,
					"max_fatigue": 95,
					"attack_power": 12,
					"is_ai": true,
				},
			],
			"seed": 42,
		},
	}
	ScreenManager.change_screen(ScreenManager.Screen.COMBAT)
