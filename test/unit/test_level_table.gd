extends GutTest

# ----------------------------------------------------------
# get_level
# ----------------------------------------------------------


func test_get_level_1_at_zero_xp() -> void:
	assert_eq(LevelTable.get_level(0), 1)


func test_get_level_2_at_200_xp() -> void:
	assert_eq(LevelTable.get_level(200), 2)


func test_get_level_3_at_500_xp() -> void:
	assert_eq(LevelTable.get_level(500), 3)


func test_get_level_4_at_1000_xp() -> void:
	assert_eq(LevelTable.get_level(1000), 4)


func test_get_level_5_at_2000_xp() -> void:
	assert_eq(LevelTable.get_level(2000), 5)


func test_get_level_11_at_15000_xp() -> void:
	assert_eq(LevelTable.get_level(15000), 11)


func test_get_level_between_thresholds() -> void:
	# 600 XP should be level 3 (500 <= 600 < 1000)
	assert_eq(LevelTable.get_level(600), 3)
	# 1500 XP should be level 4 (1000 <= 1500 < 2000)
	assert_eq(LevelTable.get_level(1500), 4)


func test_get_level_beyond_max() -> void:
	# Beyond max level should still return max level
	assert_eq(LevelTable.get_level(20000), 11)


# ----------------------------------------------------------
# get_total_xp_for_level
# ----------------------------------------------------------


func test_get_total_xp_for_level_1() -> void:
	assert_eq(LevelTable.get_total_xp_for_level(1), 0)


func test_get_total_xp_for_level_2() -> void:
	assert_eq(LevelTable.get_total_xp_for_level(2), 200)


func test_get_total_xp_for_level_11() -> void:
	assert_eq(LevelTable.get_total_xp_for_level(11), 15000)


func test_get_total_xp_for_invalid_level() -> void:
	assert_eq(LevelTable.get_total_xp_for_level(0), 0)
	assert_eq(LevelTable.get_total_xp_for_level(-1), 0)


func test_get_total_xp_for_beyond_max_level() -> void:
	assert_eq(LevelTable.get_total_xp_for_level(99), 15000)


# ----------------------------------------------------------
# get_xp_to_next_level
# ----------------------------------------------------------


func test_get_xp_to_next_level_1() -> void:
	# From level 1 to 2: 200 - 0 = 200
	assert_eq(LevelTable.get_xp_to_next_level(1), 200)


func test_get_xp_to_next_level_2() -> void:
	# From level 2 to 3: 500 - 200 = 300
	assert_eq(LevelTable.get_xp_to_next_level(2), 300)


func test_get_xp_to_next_level_10() -> void:
	# From level 10 to 11: 15000 - 12000 = 3000
	assert_eq(LevelTable.get_xp_to_next_level(10), 3000)


func test_get_xp_to_next_level_at_max() -> void:
	# At max level, should return -1
	assert_eq(LevelTable.get_xp_to_next_level(11), -1)


# ----------------------------------------------------------
# get_xp_remaining
# ----------------------------------------------------------


func test_get_xp_remaining_at_zero() -> void:
	# At 0 XP (level 1), need 200 more to reach level 2
	assert_eq(LevelTable.get_xp_remaining(0), 200)


func test_get_xp_remaining_at_600() -> void:
	# At 600 XP (level 3), need 1000 - 600 = 400 more to reach level 4
	assert_eq(LevelTable.get_xp_remaining(600), 400)


func test_get_xp_remaining_at_max() -> void:
	# At max level, should return -1
	assert_eq(LevelTable.get_xp_remaining(15000), -1)
