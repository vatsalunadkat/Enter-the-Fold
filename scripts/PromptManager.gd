extends Node2D

@onready var typing_manager = $TypingManager
var word_prompt_scene = preload("res://typing/WordPrompt.tscn")

var active_prompts: Array = []
var prompt_states: Dictionary = {}

var word_data = {}

signal prompt_completed(state_id: String)

func _ready():
	load_words()


func load_words():

	var file = FileAccess.open("res://data/word_list.json", FileAccess.READ)

	if file == null:
		push_error("Could not load word_list.json")
		return

	var json = JSON.parse_string(file.get_as_text())

	if json == null:
		push_error("Invalid JSON in word_list.json")
		return

	word_data = json


func get_random_word(difficulty: String) -> String:

	if !word_data.has(difficulty):
		return "test"

	var words = word_data[difficulty]

	if words.is_empty():
		return "test"

	return words.pick_random()


func show_prompt(word: String, anchor: Node2D, state_id: String):

	var prompt = word_prompt_scene.instantiate()

	get_tree().current_scene.add_child(prompt)

	prompt.set_word(word)
	prompt.word_id = state_id
	prompt.anchor_node = anchor

	active_prompts.append(prompt)
	prompt_states[prompt] = state_id

	typing_manager.register_word(prompt)

	prompt.word_completed.connect(_on_prompt_completed)


func _on_prompt_completed(prompt):

	if !prompt_states.has(prompt):
		return

	var state_id = prompt_states[prompt]

	prompt_states.erase(prompt)
	active_prompts.erase(prompt)

	prompt_completed.emit(state_id)

	prompt.queue_free()


func clear_all_prompts():

	for prompt in active_prompts:

		typing_manager.unregister_word(prompt)
		prompt.queue_free()

	active_prompts.clear()
	prompt_states.clear()
