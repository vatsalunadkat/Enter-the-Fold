extends Node2D

signal word_completed(word_id)

@export var fall_speed := 100.0

var word := ""
var word_id := ""
var match_index := 0

@onready var label := $WordLabel

func setup(new_word: String, id: String):
	word = new_word
	word_id = id
	match_index = 0
	update_display()

func _process(delta):
	position.y += fall_speed * delta

func can_match(char: String) -> bool:
	return match_index < word.length() and word[match_index] == char

func advance():
	match_index += 1
	update_display()

	if match_index == word.length():
		emit_signal("word_completed", word_id)
		queue_free()

func preview_match(char: String) -> bool:
	if word.begins_with(char):
		label.add_theme_color_override("default_color", Color.YELLOW)
		return true
	return false

func clear_preview():
	label.add_theme_color_override("default_color", Color.WHITE)

func update_display():
	var typed = word.substr(0, match_index)
	var remaining = word.substr(match_index)

	label.text = "[color=green]" + typed + "[/color]" + remaining
