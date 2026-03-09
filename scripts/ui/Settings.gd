extends Control

@onready var difficulty_option: OptionButton = $MarginContainer/VBoxContainer/DifficultyOption
const SETTINGS_PATH := "user://settings.cfg"

func _ready() -> void:
	if difficulty_option == null:
		push_error("Settings: DifficultyOption not found. Check node path: MarginContainer/VBoxContainer/DifficultyOption")
		return

	# Fill dropdown once
	if difficulty_option.item_count == 0:
		difficulty_option.add_item("Easy", 0)
		difficulty_option.add_item("Normal", 1)
		difficulty_option.add_item("Hard", 2)

	_load_difficulty()

	# Save whenever changed (avoid double-connecting if scene reloads)
	if not difficulty_option.item_selected.is_connected(_on_difficulty_selected):
		difficulty_option.item_selected.connect(_on_difficulty_selected)

func _on_difficulty_selected(index: int) -> void:
	var id := difficulty_option.get_item_id(index) # 0,1,2
	_save_difficulty(id)

func _save_difficulty(diff_id: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "difficulty", diff_id)
	cfg.save(SETTINGS_PATH)

func _load_difficulty() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)

	var diff_id := 1 # default Normal
	if err == OK:
		diff_id = int(cfg.get_value("game", "difficulty", 1))

	# Select matching item by id
	for i in range(difficulty_option.item_count):
		if difficulty_option.get_item_id(i) == diff_id:
			difficulty_option.select(i)
			break

func _on_back_button_pressed() -> void:
	SceneRouter.go_to("res://scenes/MainMenu.tscn")
