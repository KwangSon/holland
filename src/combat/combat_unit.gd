class_name CombatUnit

enum UnitType { NONE, PRIEST, ANATOMIST, BOWYER, GOBLIN_AMBUSHER, NECROMANCER }

# === Equipment Slots ===
var weapon = null
var head_armor_item = null
var body_armor_item = null
var accessory = null

# === Base Stats (without equipment) ===
var base_head_armor: int = 0
var base_body_armor: int = 0
var base_hp: int = 0
var base_max_hp: int = 0
var base_action_points: int = 0
var base_max_action_points: int = 0
var base_fatigue: int = 0
var base_max_fatigue: int = 0
var base_morale: int = 0
var base_resolve: int = 0
var base_initiative: int = 0
var base_melee_skill: int = 0
var base_ranged_skill: int = 0
var base_melee_defense: int = 0
var base_ranged_defense: int = 0
var base_damage: int = 0
var base_armor_penetration: int = 0
var base_chance_to_hit_head: int = 0
var base_vision: int = 0

# === Effective Stats (with equipment) ===
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
var damage: int = 0
var armor_penetration: int = 0
var chance_to_hit_head: int = 0
var vision: int = 0

# === Progression ===
var level: int = 1
var current_xp: int = 0

# === Identity & State ===
var id: String = ""
var display_name: String = ""
var team: String = ""  # "player" | "enemy"
var unit_type: UnitType = UnitType.NONE
var sprite_texture: Texture2D = null
var is_ai: bool = false
var position: Vector2i = Vector2i.ZERO
var visual_position: Vector2 = Vector2.ZERO
var alive: bool = true
var has_acted: bool = false


static func create(data: Dictionary) -> CombatUnit:
	var u := CombatUnit.new()
	u.id = data.get("id", "")
	u.display_name = data.get("display_name", "")
	u.team = data.get("team", "")
	u.unit_type = data.get("unit_type", UnitType.NONE)
	u.sprite_texture = data.get("sprite_texture", null)
	u.is_ai = data.get("is_ai", false)
	u.position = data.get("position", Vector2i.ZERO)

	# Equipment
	u.weapon = data.get("weapon", null)
	u.head_armor_item = data.get("head_armor_item", null)
	u.body_armor_item = data.get("body_armor_item", null)
	u.accessory = data.get("accessory", null)

	# Base Stats
	u.base_head_armor = data.get("head_armor", 0)
	u.base_body_armor = data.get("body_armor", 0)
	u.base_max_hp = data.get("max_hp", 10)
	u.base_hp = data.get("hp", u.base_max_hp)
	u.base_max_action_points = data.get("max_action_points", 4)
	u.base_action_points = data.get("action_points", u.base_max_action_points)
	u.base_max_fatigue = data.get("max_fatigue", 100)
	u.base_fatigue = data.get("fatigue", 0)
	u.base_morale = data.get("morale", 100)
	u.base_resolve = data.get("resolve", 100)
	u.base_initiative = data.get("initiative", 0)
	u.base_melee_skill = data.get("melee_skill", 0)
	u.base_ranged_skill = data.get("ranged_skill", 0)
	u.base_melee_defense = data.get("melee_defense", 0)
	u.base_ranged_defense = data.get("ranged_defense", 0)
	u.base_damage = data.get("damage", 0)
	u.base_armor_penetration = data.get("armor_penetration", 0)
	u.base_chance_to_hit_head = data.get("chance_to_hit_head", 0)
	u.base_vision = data.get("vision", 0)

	# Progression
	u.level = data.get("level", 1)
	u.current_xp = data.get("current_xp", 0)

	# Apply equipment bonuses
	u.recalculate_stats()

	return u


## Recalculate all effective stats from base stats + equipment bonuses
func recalculate_stats() -> void:
	# Start with base stats
	head_armor = base_head_armor
	body_armor = base_body_armor
	max_hp = base_max_hp
	hp = base_hp
	max_action_points = base_max_action_points
	action_points = base_action_points
	max_fatigue = base_max_fatigue
	fatigue = base_fatigue
	morale = base_morale
	resolve = base_resolve
	initiative = base_initiative
	melee_skill = base_melee_skill
	ranged_skill = base_ranged_skill
	melee_defense = base_melee_defense
	ranged_defense = base_ranged_defense
	damage = base_damage
	armor_penetration = base_armor_penetration
	chance_to_hit_head = base_chance_to_hit_head
	vision = base_vision

	# Apply equipment bonuses
	_apply_item_bonus(weapon)
	_apply_item_bonus(head_armor_item)
	_apply_item_bonus(body_armor_item)
	_apply_item_bonus(accessory)


func _apply_item_bonus(item) -> void:
	if item == null:
		return
	head_armor += item.head_armor
	body_armor += item.body_armor
	max_hp += item.max_hp
	hp += item.hp
	max_action_points += item.max_action_points
	action_points += item.action_points
	max_fatigue += item.max_fatigue
	fatigue += item.fatigue
	morale += item.morale
	resolve += item.resolve
	initiative += item.initiative
	melee_skill += item.melee_skill
	ranged_skill += item.ranged_skill
	melee_defense += item.melee_defense
	ranged_defense += item.ranged_defense
	damage += item.damage
	armor_penetration += item.armor_penetration
	chance_to_hit_head += item.chance_to_hit_head
	vision += item.vision


## Equip an item to the specified slot
func equip_item(slot: String, item) -> void:
	match slot:
		"weapon":
			weapon = item
		"head":
			head_armor_item = item
		"body":
			body_armor_item = item
		"accessory":
			accessory = item
	recalculate_stats()


## Unequip an item from the specified slot
func unequip_item(slot: String) -> void:
	match slot:
		"weapon":
			weapon = null
		"head":
			head_armor_item = null
		"body":
			body_armor_item = null
		"accessory":
			accessory = null
	recalculate_stats()
