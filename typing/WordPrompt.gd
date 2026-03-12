extends Node2D

signal word_completed(word_id)

var word := ""
var word_id := ""
var match_index := 0

@onready var label := $WordLabel
@onready var backdrop := $Backdrop
@export var anchor_node: Node2D


func set_word(new_word: String):
	word = new_word
	match_index = 0
	update_display()


func _process(_delta):

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

	label.text = "[center][color=lime]" + typed + "[/color][color=white]" + remaining + "[/color][/center]"

	# Resize backdrop to fit word length
	var char_width := 16
	var half_w: float = max(word.length() * char_width / 2.0, 40.0)
	backdrop.offset_left = -half_w - 6
	backdrop.offset_right = half_w + 6
	label.offset_left = -half_w - 6
	label.offset_right = half_w + 6
	
func reset_word():
	match_index = 0
	update_display()
	
