extends Control

# UI nodes
@onready var difficulty_option: OptionButton = $MarginContainer/VBoxContainer/DifficultyOption
@onready var word_difficulty_option: OptionButton = $MarginContainer/VBoxContainer/WordDifficultyOption
@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $MarginContainer/VBoxContainer/SFXSlider

const SETTINGS_PATH := "user://settings.cfg"

func _ready() -> void:
	_populate_dropdowns()
	_load_settings()
	_connect_signals()

func _populate_dropdowns() -> void:
	var labels := ["Very Easy", "Easy", "Medium", "Hard", "Very Hard"]
	for opt in [difficulty_option, word_difficulty_option]:
		if opt.item_count == 0:
			for i in range(labels.size()):
				opt.add_item(labels[i], i)

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)

	var diff_id: int = GameConfig.Difficulty.MEDIUM
	var word_diff_id: int = GameConfig.Difficulty.MEDIUM
	var music_db: float = -14.0
	var sfx_db: float = 3.0

	if err == OK:
		diff_id = int(cfg.get_value("game", "difficulty", diff_id))
		word_diff_id = int(cfg.get_value("game", "word_difficulty", word_diff_id))
		music_db = float(cfg.get_value("audio", "music_db", music_db))
		sfx_db = float(cfg.get_value("audio", "sfx_db", sfx_db))

	GameConfig.set_difficulty(diff_id)
	GameConfig.set_word_difficulty(word_diff_id)

	_select_item(difficulty_option, diff_id)
	_select_item(word_difficulty_option, word_diff_id)

	music_slider.value = music_db
	sfx_slider.value = sfx_db
	_apply_bus_volume("Music", music_db)
	_apply_bus_volume("SFX", sfx_db)

func _connect_signals() -> void:
	if not difficulty_option.item_selected.is_connected(_on_difficulty_selected):
		difficulty_option.item_selected.connect(_on_difficulty_selected)
	if not word_difficulty_option.item_selected.is_connected(_on_word_difficulty_selected):
		word_difficulty_option.item_selected.connect(_on_word_difficulty_selected)
	if not music_slider.value_changed.is_connected(_on_music_changed):
		music_slider.value_changed.connect(_on_music_changed)
	if not sfx_slider.value_changed.is_connected(_on_sfx_changed):
		sfx_slider.value_changed.connect(_on_sfx_changed)

func _select_item(opt: OptionButton, id: int) -> void:
	for i in range(opt.item_count):
		if opt.get_item_id(i) == id:
			opt.select(i)
			return

func _on_difficulty_selected(index: int) -> void:
	var id: int = difficulty_option.get_item_id(index)
	GameConfig.set_difficulty(id)
	_save_settings()

func _on_word_difficulty_selected(index: int) -> void:
	var id: int = word_difficulty_option.get_item_id(index)
	GameConfig.set_word_difficulty(id)
	_save_settings()

func _on_music_changed(value: float) -> void:
	_apply_bus_volume("Music", value)
	_save_settings()

func _on_sfx_changed(value: float) -> void:
	_apply_bus_volume("SFX", value)
	_save_settings()

func _apply_bus_volume(bus_name: String, db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, db)
		AudioServer.set_bus_mute(idx, db <= -40.0)

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "difficulty", GameConfig.current_difficulty)
	cfg.set_value("game", "word_difficulty", GameConfig.word_difficulty)
	cfg.set_value("audio", "music_db", music_slider.value)
	cfg.set_value("audio", "sfx_db", sfx_slider.value)
	cfg.save(SETTINGS_PATH)

func _on_back_button_pressed() -> void:
	SceneRouter.go_to("res://scenes/MainMenu.tscn")
