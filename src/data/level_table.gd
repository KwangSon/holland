class_name LevelTable

## Total XP needed for each level (index = level)
## Level 1 starts at 0 XP (index 0 is unused for convenience)
const LEVEL_XP_TABLE: Array[int] = [
	0,  # Level 1 (starting point)
	200,  # Level 2
	500,  # Level 3
	1000,  # Level 4
	2000,  # Level 5
	3500,  # Level 6
	5000,  # Level 7
	7000,  # Level 8
	9000,  # Level 9
	12000,  # Level 10
	15000,  # Level 11
]


## Returns the level for a given total XP amount.
## Index 0 = Level 1, Index 1 = Level 2, etc.
static func get_level(total_xp: int) -> int:
	for i: int in range(LEVEL_XP_TABLE.size() - 1, -1, -1):
		if total_xp >= LEVEL_XP_TABLE[i]:
			return i + 1  # Convert index to level (index 0 = level 1)
	return 1


## Returns the total XP needed to reach the specified level.
static func get_total_xp_for_level(level: int) -> int:
	if level < 1:
		return 0
	if level > LEVEL_XP_TABLE.size():
		return LEVEL_XP_TABLE[-1]
	return LEVEL_XP_TABLE[level - 1]  # Convert level to index (level 1 = index 0)


## Returns XP needed to reach the next level from current level.
## Returns -1 if already at max level.
static func get_xp_to_next_level(level: int) -> int:
	if level < 1 or level >= LEVEL_XP_TABLE.size():
		return -1
	return LEVEL_XP_TABLE[level] - LEVEL_XP_TABLE[level - 1]  # XP for (level+1) - XP for level


## Returns XP needed from current XP to reach the next level.
static func get_xp_remaining(current_xp: int) -> int:
	var level: int = get_level(current_xp)
	if level >= LEVEL_XP_TABLE.size():
		return -1
	return LEVEL_XP_TABLE[level] - current_xp  # XP for next level - current XP
