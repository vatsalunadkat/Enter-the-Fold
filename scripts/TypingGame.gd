extends Node2D

@onready var manager = $TypingManager
var word_scene = preload("res://typing/WordPrompt.tscn")

var easy_words: Array = []
var word_pool: Array = []

func _ready():
	randomize()
	load_words()
	spawn_loop()

# -------------------------
# LOAD WORDS FROM JSON
# -------------------------
func load_words():
	var file = FileAccess.open("res://data/word_list.json", FileAccess.READ)
	if file == null:
		print("ERROR: Could not open word_list.json")
		return

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(content) != OK:
		print("ERROR: JSON parse failed")
		return

	var data = json.data

	if "easy" in data:
		easy_words = data["easy"]
		reset_word_pool()
	else:
		print("ERROR: 'easy' key not found")

func reset_word_pool():
	word_pool = easy_words.duplicate()
	word_pool.shuffle()

# -------------------------
# ENDLESS SPAWN LOOP
# -------------------------
func spawn_loop():
	# Spawn immediately
	spawn_random_word()

	while true:
		await get_tree().create_timer(0.7).timeout
		spawn_random_word()

func spawn_random_word():
	if word_pool.size() == 0:
		reset_word_pool()

	var next_word = word_pool.pop_back()
	spawn_word(next_word)

func spawn_word(word: String):
	var instance = word_scene.instantiate()
	add_child(instance)

	instance.position = Vector2(randi() % 600 + 100, -50)
	instance.setup(word, word)

	manager.register_word(instance)
