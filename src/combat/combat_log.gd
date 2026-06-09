class_name CombatLog extends RefCounted

var max_lines: int = 4
var _lines: Array[String] = []


func append(message: String) -> String:
	_lines.append(message)
	while _lines.size() > max_lines:
		_lines.pop_front()
	return get_text()


func get_text() -> String:
	return "\n".join(_lines)


func get_lines() -> Array[String]:
	return _lines.duplicate()
