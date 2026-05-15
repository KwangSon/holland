class_name CombatUnit

var id: String = ""
var display_name: String = ""
var team: String = ""  # "player" | "enemy"
var position: Vector2i = Vector2i.ZERO
var alive: bool = true
var hp: int = 0
var max_hp: int = 0
var armor: int = 0
var ap: int = 0
var max_ap: int = 0
var initiative: int = 0
var melee_skill: int = 0
var melee_defense: int = 0
var damage_min: int = 0
var damage_max: int = 0
var move_range: int = 0


static func create(data: Dictionary) -> CombatUnit:
	var u := CombatUnit.new()
	u.id = data.get("id", "")
	u.display_name = data.get("display_name", "")
	u.team = data.get("team", "")
	u.position = data.get("position", Vector2i.ZERO)
	u.max_hp = data.get("max_hp", 10)
	u.hp = data.get("hp", u.max_hp)
	u.armor = data.get("armor", 0)
	u.max_ap = data.get("max_ap", 2)
	u.ap = data.get("ap", u.max_ap)
	u.initiative = data.get("initiative", 5)
	u.melee_skill = data.get("melee_skill", 50)
	u.melee_defense = data.get("melee_defense", 10)
	u.damage_min = data.get("damage_min", 5)
	u.damage_max = data.get("damage_max", 15)
	u.move_range = data.get("move_range", 3)
	return u
