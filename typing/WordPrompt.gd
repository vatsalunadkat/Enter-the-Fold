extends Node2D

signal word_completed(word_id)

var word := ""
var word_id := ""
var match_index := 0

@onready var label := $WordLabel
@onready var backdrop := $Backdrop
@export var anchor_node: Node2D

# Font size tuned for readability on 6" portrait mobile screens
const FONT_SIZE := 20
const CHAR_WIDTH := 13
const MIN_HALF_W := 36.0
const PAD_H := 8.0  # horizontal padding beyond text
const PAD_V := 5.0  # vertical padding

func set_word(new_word: String):
	word = new_word
	match_index = 0
	update_display()

func _process(_delta):
	if anchor_node != null:
		global_position = anchor_node.global_position + Vector2(0, -50)

func can_match(c: String) -> bool:
	return match_index < word.length() and word[match_index] == c

func advance():
	match_index += 1
	update_display()
	if match_index >= word.length():
		word_completed.emit(self)

func reset_progress():
	match_index = 0
	update_display()

func update_display():
	var typed := word.substr(0, match_index)
	var remaining := word.substr(match_index)
	label.text = "[center][color=lime]" + typed + "[/color][color=white]" + remaining + "[/color][/center]"
	_resize_to_word()

func reset_word():
	match_index = 0
	update_display()

# ─── Wrong-letter feedback ────────────────────────────────────────────────────

func show_wrong_char(wrong_char: String) -> void:
	var wrong_label := Label.new()
	wrong_label.text = wrong_char.to_upper()
	wrong_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))
	wrong_label.add_theme_font_size_override("font_size", 18)
	# Position near the next-expected character in the word
	var x_offset := (match_index - word.length() * 0.5) * CHAR_WIDTH
	wrong_label.position = Vector2(x_offset, -38)
	add_child(wrong_label)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(wrong_label, "position:y", wrong_label.position.y - 22, 0.4)
	tw.tween_property(wrong_label, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(wrong_label.queue_free)

# ─── Shake animation ─────────────────────────────────────────────────────────

func _shake() -> void:
	var original_pos := position
	var tw := create_tween()
	tw.tween_property(self, "position", original_pos + Vector2(4, 0), 0.03)
	tw.tween_property(self, "position", original_pos - Vector2(4, 0), 0.03)
	tw.tween_property(self, "position", original_pos + Vector2(2, 0), 0.03)
	tw.tween_property(self, "position", original_pos, 0.03)

# ─── Private helpers ─────────────────────────────────────────────────────────

func _resize_to_word() -> void:
	var half_w: float = max(word.length() * CHAR_WIDTH / 2.0, MIN_HALF_W)
	var left := -(half_w + PAD_H)
	var right :=  (half_w + PAD_H)

	# Backdrop (Panel or ColorRect — both use offset_* for anchored nodes)
	backdrop.offset_left  = left
	backdrop.offset_right = right

	# Label gets the same horizontal span, slightly inset for padding
	label.offset_left  = left
	label.offset_right = right
