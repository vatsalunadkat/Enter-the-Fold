extends Control

# Difficulty dropdown
@onready var difficulty_option: OptionButton = $MarginContainer/VBoxContainer/DifficultyOption

# Local settings file
const SETTINGS_PATH := "user://settings.cfg"

func _ready() -> void:
	# Make sure the dropdown exists
	if difficulty_option == null:
		push_error("Settings: DifficultyOption not found. Check node path: MarginContainer/VBoxContainer/DifficultyOption")
		return

	# Add difficulty options once
	if difficulty_option.item_count == 0:
		difficulty_option.add_item("Very Easy", GameConfig.Difficulty.VERY_EASY)
		difficulty_option.add_item("Easy", GameConfig.Difficulty.EASY)
		difficulty_option.add_item("Medium", GameConfig.Difficulty.MEDIUM)
		difficulty_option.add_item("Hard", GameConfig.Difficulty.HARD)
		difficulty_option.add_item("Very Hard", GameConfig.Difficulty.VERY_HARD)

	# Load saved difficulty
	_load_difficulty()

	# Connect selection signal once
	if not difficulty_option.item_selected.is_connected(_on_difficulty_selected):
		difficulty_option.item_selected.connect(_on_difficulty_selected)

func _on_difficulty_selected(index: int) -> void:
	# Get selected difficulty id
	var id: int = difficulty_option.get_item_id(index)

	# Update global difficulty and save it
	GameConfig.set_difficulty(id)
	_save_difficulty(id)

func _save_difficulty(diff_id: int) -> void:
	var cfg := ConfigFile.new()

	# Store difficulty in config file
	cfg.set_value("game", "difficulty", diff_id)
	cfg.save(SETTINGS_PATH)

func _load_difficulty() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)

	# Default difficulty
	var diff_id: int = GameConfig.Difficulty.MEDIUM

	# Read saved difficulty if file exists
	if err == OK:
		diff_id = int(cfg.get_value("game", "difficulty", GameConfig.Difficulty.MEDIUM))

	# Apply saved difficulty
	GameConfig.set_difficulty(diff_id)

	# Select matching dropdown item
	for i in range(difficulty_option.item_count):
		if difficulty_option.get_item_id(i) == GameConfig.current_difficulty:
			difficulty_option.select(i)
			break

func _on_back_button_pressed() -> void:
	# Return to main menu
	SceneRouter.go_to("res://scenes/MainMenu.tscn")
