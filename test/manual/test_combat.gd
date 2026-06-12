extends Node2D

const EncounterRegistryScript := preload("res://src/data/encounter_registry.gd")


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
				"skill_ids": [CombatSkillRegistry.BASIC_ATTACK_ID, CombatSkillRegistry.SHIELDWALL_ID],
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
				"skill_ids": [CombatSkillRegistry.BASIC_ATTACK_ID, CombatSkillRegistry.MACE_STRIKE_ID],
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
				"skill_ids": [CombatSkillRegistry.RANGED_SHOT_ID, CombatSkillRegistry.BASIC_ATTACK_ID],
				# 장비: Crossbow + Sallet + Ranger's Boots
				"weapon": Item.crossbow(),
				"head_armor_item": Item.sallet(),
				"accessory": Item.rangers_boots(),
			},
		],
		"encounter": EncounterRegistryScript.get_encounter(
			EncounterRegistryScript.BANDIT_SKIRMISH_ID
		).to_rna(),
	}
	ScreenManager.change_screen(ScreenManager.Screen.COMBAT)
