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


		# --------------------------------
		# CASE 1 : WORD IS ALREADY LOCKED
		# --------------------------------
		if focused_word != null:

			if focused_word.can_match(char_input):
				focused_word.advance()

			return


		# --------------------------------
		# CHECK IF USER ALREADY STARTED A WORD
		# --------------------------------
		var in_progress = []

		for word in active_words:
			if word.match_index > 0:
				in_progress.append(word)


		# --------------------------------
		# CONTINUE ONLY THOSE WORDS
		# --------------------------------
		if in_progress.size() > 0:

			var still_valid = []

			for word in in_progress:

				if word.can_match(char_input):
					word.advance()
					still_valid.append(word)
				else:
					word.reset_word()


			# lock if only one remains
			if still_valid.size() == 1:
				focused_word = still_valid[0]

				for word in active_words:
					if word != focused_word:
						word.reset_word()

			return


		# --------------------------------
		# USER STARTING A NEW WORD
		# --------------------------------
		var candidates = []

		for word in active_words:

			if word.can_match(char_input):
				word.advance()
				candidates.append(word)


		# reset others
		for word in active_words:
			if word not in candidates:
				word.reset_word()


		if candidates.size() == 1:
			focused_word = candidates[0]
