extends Node

var active_words: Array = []
var focused_word: Node = null

func register_word(word_node):
	active_words.append(word_node)
	word_node.connect("word_completed", Callable(self, "_on_word_completed"))

func _on_word_completed(word_id):
	active_words = active_words.filter(func(w): return w.word_id != word_id)
	focused_word = null

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		var char_input = char(event.unicode).to_lower()
		if char_input == "":
			return

		# If already locked
		if focused_word != null:
			if focused_word.can_match(char_input):
				focused_word.advance()
			return

		# If NOT locked
		var matching_words = []

		for word in active_words:
			if word.can_match(char_input):
				matching_words.append(word)

		# Advance all matches
		for word in matching_words:
			word.advance()

		# If exactly one remains viable, lock it
		var still_valid = []

		for word in matching_words:
			if word.match_index < word.word.length():
				still_valid.append(word)

		if still_valid.size() == 1:
			focused_word = still_valid[0]
