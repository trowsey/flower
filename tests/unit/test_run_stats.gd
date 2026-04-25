extends GutTest

const RunStatsScript = preload("res://scripts/run_stats.gd")


func test_record_kill_increments() -> void:
	var s = RunStatsScript.new()
	s.record_kill(false)
	s.record_kill(true)
	assert_eq(s.kills, 2)
	assert_eq(s.elite_kills, 1)
	s.free()


func test_record_gold() -> void:
	var s = RunStatsScript.new()
	s.record_gold(15)
	s.record_gold(7)
	assert_eq(s.gold_collected, 22)
	s.free()


func test_record_level_keeps_max() -> void:
	var s = RunStatsScript.new()
	s.record_level(5)
	s.record_level(3)
	s.record_level(7)
	assert_eq(s.peak_level, 7)
	s.free()


func test_format_time() -> void:
	var s = RunStatsScript.new()
	s.time_alive = 65.0
	assert_eq(s.format_time(), "01:05")
	s.free()


func test_summary_contains_fields() -> void:
	var s = RunStatsScript.new()
	s.record_kill(false)
	s.record_gold(10)
	s.time_alive = 30.0
	var sum := s.summary()
	assert_true("Kills" in sum)
	assert_true("Gold" in sum)
	assert_true("Time" in sum)
	s.free()


func test_record_wave_cleared() -> void:
	var s = RunStatsScript.new()
	s.record_wave_cleared()
	s.record_wave_cleared()
	assert_eq(s.waves_cleared, 2)
	s.free()
