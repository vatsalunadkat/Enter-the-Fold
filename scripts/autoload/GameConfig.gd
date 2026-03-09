extends Node

# 0..2 for 3 difficulty options
var current_difficulty: int = 0  # default: easy option

func set_difficulty(value: int) -> void:
	current_difficulty = clamp(value, 0, 2)
