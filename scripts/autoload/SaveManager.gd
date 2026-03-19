extends Node

const SAVE_PATH := "user://endless_save.cfg"

signal save_completed
signal load_completed

func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "money", GameState.money)
	cfg.set_value("progress", "endless_day", GameConfig.endless_day)
	cfg.set_value("progress", "current_level", GameConfig.current_level)
	cfg.set_value("progress", "current_difficulty", GameConfig.current_difficulty)
	cfg.set_value("progress", "word_difficulty", GameConfig.word_difficulty)
	
	# Save purchased upgrades (copy from UpgradeManager's data)
	for upgrade_id in UpgradeManager.purchased_upgrades.keys():
		cfg.set_value("upgrades", upgrade_id, UpgradeManager.purchased_upgrades[upgrade_id])
	
	var err := cfg.save(SAVE_PATH)
	if err == OK:
		print("[SaveManager] Game saved — Day %d, $%d" % [GameConfig.endless_day, GameState.money])
		save_completed.emit()
	else:
		push_error("[SaveManager] Failed to save: %s" % err)

func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		print("[SaveManager] No save file found")
		return false
	
	GameState.money = cfg.get_value("progress", "money", 0)
	GameConfig.endless_mode = true
	GameConfig.endless_day = cfg.get_value("progress", "endless_day", 1)
	GameConfig.current_level = cfg.get_value("progress", "current_level", 1)
	GameConfig.current_difficulty = cfg.get_value("progress", "current_difficulty", 2)
	GameConfig.word_difficulty = cfg.get_value("progress", "word_difficulty", 2)
	
	# Restore purchased upgrades
	UpgradeManager.purchased_upgrades.clear()
	if cfg.has_section("upgrades"):
		for key in cfg.get_section_keys("upgrades"):
			UpgradeManager.purchased_upgrades[key] = cfg.get_value("upgrades", key, 0)
	UpgradeManager._recalculate_effects()
	
	print("[SaveManager] Game loaded — Day %d, $%d" % [GameConfig.endless_day, GameState.money])
	load_completed.emit()
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("[SaveManager] Save file deleted")
		
