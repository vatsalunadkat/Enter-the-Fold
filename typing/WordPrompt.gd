extends Node2D

signal word_completed(word_id)

@export var fall_speed := 60.0   # slower fall

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


func reset_progress():
	match_index = 0
	update_display()


func update_display():
	var typed = word.substr(0, match_index)
	var remaining = word.substr(match_index)

	label.text = "[center][font_size=36][color=green]" + typed + "[/color]" + remaining + "[/font_size][/center]"
	
func reset_word():
	match_index = 0
	update_display()
