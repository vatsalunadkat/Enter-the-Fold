extends Node

var active_words: Array = []
var focused_word: Node = null

func register_word(word_node):
	active_words.append(word_node)
	word_node.connect("word_completed", Callable(self, "_on_word_completed"))

func unregister_word(word_node):
	if active_words.has(word_node):
		active_words.erase(word_node)
	if focused_word == word_node:
		focused_word = null

func _on_word_completed(prompt):
	active_words.erase(prompt)
	if focused_word == prompt:
		focused_word = null

func _input(event: InputEvent) -> void:
	# On mobile, input is driven by PromptManager's LineEdit bridge instead.
	if OS.has_feature("mobile"):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var c: String = char(event.unicode).to_lower()
		if c != "":
			route_char(c)

func route_char(char_input: String) -> void:
	# ────────────────────────────────────────────────
	# CASE 1 : A WORD IS LOCKED (focused)
	# ────────────────────────────────────────────────
	if focused_word != null:
		if focused_word.can_match(char_input):
			focused_word.advance()
		else:
			_wrong_input(focused_word, char_input)
		return

	# ────────────────────────────────────────────────
	# CASE 2 : WORDS ALREADY IN PROGRESS
	# ────────────────────────────────────────────────
	var in_progress: Array = []
	for w in active_words:
		if w.match_index > 0:
			in_progress.append(w)

	if in_progress.size() > 0:
		var still_valid: Array = []
		for w in in_progress:
			if w.can_match(char_input):
				w.advance()
				still_valid.append(w)
			else:
				w.reset_word()

		if still_valid.size() == 0:
			# All in-progress words rejected — give feedback on whichever
			# was the sole candidate before reset (use first as proxy)
			if in_progress.size() > 0:
				_wrong_input(in_progress[0], char_input)
		elif still_valid.size() == 1:
			focused_word = still_valid[0]
			for w in active_words:
				if w != focused_word:
					w.reset_word()
		return

	# ────────────────────────────────────────────────
	# CASE 3 : STARTING A NEW WORD
	# ────────────────────────────────────────────────
	var candidates: Array = []
	for w in active_words:
		if w.can_match(char_input):
			w.advance()
			candidates.append(w)

	for w in active_words:
		if w not in candidates:
			w.reset_word()

	if candidates.size() == 0 and active_words.size() > 0:
		# No word starts with this character — show feedback on nearest word
		# (or just the first one, since we have no single target)
		_wrong_input(active_words[0], char_input)
	elif candidates.size() == 1:
		focused_word = candidates[0]

# ─── Shared wrong-input helper ───────────────────────────────────────────────

func _wrong_input(word_node: Node, char_input: String) -> void:
	word_node.show_wrong_char(char_input)
	word_node._shake()

	# Optional: forward to AudioManager if present
	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am.has_method("play_wrong_key"):
			am.play_wrong_key()
