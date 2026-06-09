extends GutTest

const CombatLogScript := preload("res://src/combat/combat_log.gd")


func test_append_returns_multiline_log_text() -> void:
	var combat_log := CombatLogScript.new()

	assert_eq(combat_log.append("첫 행동"), "첫 행동")
	assert_eq(combat_log.append("둘째 행동"), "첫 행동\n둘째 행동")


func test_log_keeps_recent_lines_only() -> void:
	var combat_log := CombatLogScript.new()
	combat_log.max_lines = 2

	combat_log.append("1")
	combat_log.append("2")
	assert_eq(combat_log.append("3"), "2\n3")
	assert_eq(combat_log.get_lines(), ["2", "3"])
