extends Node2D

signal word_completed(word_id)

var word := ""
var word_id := ""
var match_index := 0

@onready var label := $WordLabel
@export var anchor_node: Node2D


func set_word(new_word: String):
	word = new_word
	match_index = 0
	update_display()


func _process(delta):

	if anchor_node != null:
		global_position = anchor_node.global_position + Vector2(0, -50)


func can_match(char: String) -> bool:
	return match_index < word.length() and word[match_index] == char


func advance():
	match_index += 1
	update_display()

	if match_index >= word.length():
		word_completed.emit(self)


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
	
