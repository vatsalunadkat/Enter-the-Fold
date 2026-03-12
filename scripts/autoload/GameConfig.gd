extends Node

enum Difficulty {
	VERY_EASY,
	EASY,
	MEDIUM,
	HARD,
	VERY_HARD
}

var current_difficulty: int = Difficulty.MEDIUM
var word_difficulty: int = Difficulty.MEDIUM
var current_level: int = 1

# Endless mode state
var endless_mode: bool = false
var endless_day: int = 1

func set_difficulty(value: int) -> void:
	current_difficulty = clamp(value, Difficulty.VERY_EASY, Difficulty.VERY_HARD)

func set_word_difficulty(value: int) -> void:
	word_difficulty = clamp(value, Difficulty.VERY_EASY, Difficulty.VERY_HARD)

func set_level(level: int) -> void:
	current_level = clamp(level, 1, 10)

func start_endless_mode() -> void:
	endless_mode = true
	endless_day = 1
	current_level = 1  # Start at level 1 in endless

func reset_endless() -> void:
	endless_mode = false
	endless_day = 1
