class_name CombatUnit

var id: String = ""
var display_name: String = ""
var team: String = ""  # "player" | "enemy"
var is_ai: bool = false
var position: Vector2i = Vector2i.ZERO
var alive: bool = true
var hp: int = 0
var max_hp: int = 0
var fatigue: int = 0
var max_fatigue: int = 0
var attack_power: int = 0
var has_acted: bool = false


static func create(data: Dictionary) -> CombatUnit:
	var u := CombatUnit.new()
	u.id = data.get("id", "")
	u.display_name = data.get("display_name", "")
	u.team = data.get("team", "")
	u.is_ai = data.get("is_ai", false)
	u.position = data.get("position", Vector2i.ZERO)
	u.max_hp = data.get("max_hp", 10)
	u.hp = data.get("hp", u.max_hp)
	u.max_fatigue = data.get("max_fatigue", 100)
	u.fatigue = data.get("fatigue", 0)
	u.attack_power = data.get("attack_power", 5)
	return u
