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

func set_difficulty(value: int) -> void:
	current_difficulty = clamp(value, Difficulty.VERY_EASY, Difficulty.VERY_HARD)

func set_word_difficulty(value: int) -> void:
	word_difficulty = clamp(value, Difficulty.VERY_EASY, Difficulty.VERY_HARD)

func set_level(level: int) -> void:
	current_level = clamp(level, 1, 10)
