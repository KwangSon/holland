class_name Item

enum ItemType { WEAPON, HEAD_ARMOR, BODY_ARMOR, ACCESSORY }

var name: String = ""
var type: ItemType = ItemType.WEAPON
var icon: Texture2D = null

# Stat bonuses
var damage: int = 0
var armor_penetration: int = 0
var chance_to_hit_head: int = 0
var head_armor: int = 0
var body_armor: int = 0
var hp: int = 0
var max_hp: int = 0
var action_points: int = 0
var max_action_points: int = 0
var fatigue: int = 0
var max_fatigue: int = 0
var morale: int = 0
var resolve: int = 0
var initiative: int = 0
var melee_skill: int = 0
var ranged_skill: int = 0
var melee_defense: int = 0
var ranged_defense: int = 0
var vision: int = 0


static func create(data: Dictionary) -> Item:
	var item := Item.new()
	item.name = data.get("name", "")
	item.type = data.get("type", ItemType.WEAPON)
	item.damage = data.get("damage", 0)
	item.armor_penetration = data.get("armor_penetration", 0)
	item.chance_to_hit_head = data.get("chance_to_hit_head", 0)
	item.head_armor = data.get("head_armor", 0)
	item.body_armor = data.get("body_armor", 0)
	item.hp = data.get("hp", 0)
	item.max_hp = data.get("max_hp", 0)
	item.action_points = data.get("action_points", 0)
	item.max_action_points = data.get("max_action_points", 0)
	item.fatigue = data.get("fatigue", 0)
	item.max_fatigue = data.get("max_fatigue", 0)
	item.morale = data.get("morale", 0)
	item.resolve = data.get("resolve", 0)
	item.initiative = data.get("initiative", 0)
	item.melee_skill = data.get("melee_skill", 0)
	item.ranged_skill = data.get("ranged_skill", 0)
	item.melee_defense = data.get("melee_defense", 0)
	item.ranged_defense = data.get("ranged_defense", 0)
	item.vision = data.get("vision", 0)

	# 아이콘 설정 (이름 기반)
	item.icon = _get_icon_for_name(item.name)

	return item


static func _get_icon_for_name(_name: String) -> Texture2D:
	# TODO: 실제 아이콘 에셋이 준비되면 매핑 추가
	# 현재는 null 반환 (UI 에서 빈 아이콘으로 표시)
	return null


# ============================================================
# Weapons
# ============================================================


static func longsword() -> Item:
	return create(
		{
			"name": "Longsword",
			"type": ItemType.WEAPON,
			"damage": 3,
			"melee_skill": 2,
		}
	)


static func battle_axe() -> Item:
	return create(
		{
			"name": "Battle Axe",
			"type": ItemType.WEAPON,
			"damage": 4,
			"armor_penetration": 10,
		}
	)


static func bow() -> Item:
	return create(
		{
			"name": "Bow",
			"type": ItemType.WEAPON,
			"damage": 2,
			"ranged_skill": 3,
		}
	)


static func crossbow() -> Item:
	return create(
		{
			"name": "Crossbow",
			"type": ItemType.WEAPON,
			"damage": 3,
			"armor_penetration": 15,
			"chance_to_hit_head": 5,
		}
	)


static func mace() -> Item:
	return create(
		{
			"name": "Mace",
			"type": ItemType.WEAPON,
			"damage": 2,
			"armor_penetration": 20,
		}
	)


static func spear() -> Item:
	return create(
		{
			"name": "Spear",
			"type": ItemType.WEAPON,
			"damage": 2,
			"melee_skill": 1,
			"initiative": 5,
		}
	)


# ============================================================
# Head Armor
# ============================================================


static func leather_cap() -> Item:
	return create(
		{
			"name": "Leather Cap",
			"type": ItemType.HEAD_ARMOR,
			"head_armor": 5,
		}
	)


static func kettle_hat() -> Item:
	return create(
		{
			"name": "Kettle Hat",
			"type": ItemType.HEAD_ARMOR,
			"head_armor": 8,
			"vision": 1,
		}
	)


static func nasal_helm() -> Item:
	return create(
		{
			"name": "Nasal Helm",
			"type": ItemType.HEAD_ARMOR,
			"head_armor": 12,
		}
	)


static func sallet() -> Item:
	return create(
		{
			"name": "Sallet",
			"type": ItemType.HEAD_ARMOR,
			"head_armor": 10,
			"initiative": 3,
		}
	)


# ============================================================
# Body Armor
# ============================================================


static func gambeson() -> Item:
	return create(
		{
			"name": "Gambeson",
			"type": ItemType.BODY_ARMOR,
			"body_armor": 8,
			"max_fatigue": 10,
		}
	)


static func chainmail_hauberk() -> Item:
	return create(
		{
			"name": "Chainmail Hauberk",
			"type": ItemType.BODY_ARMOR,
			"body_armor": 15,
			"max_fatigue": 20,
		}
	)


static func plate_armor() -> Item:
	return create(
		{
			"name": "Plate Armor",
			"type": ItemType.BODY_ARMOR,
			"body_armor": 25,
			"max_fatigue": 35,
			"melee_defense": 2,
		}
	)


# ============================================================
# Accessories
# ============================================================


static func rangers_boots() -> Item:
	return create(
		{
			"name": "Ranger's Boots",
			"type": ItemType.ACCESSORY,
			"vision": 2,
			"initiative": 5,
		}
	)


static func warriors_gloves() -> Item:
	return create(
		{
			"name": "Warrior's Gloves",
			"type": ItemType.ACCESSORY,
			"melee_skill": 2,
			"ranged_skill": 1,
		}
	)


static func morale_banner() -> Item:
	return create(
		{
			"name": "Morale Banner",
			"type": ItemType.ACCESSORY,
			"morale": 15,
		}
	)
