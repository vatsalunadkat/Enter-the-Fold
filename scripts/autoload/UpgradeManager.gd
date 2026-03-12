extends Node
## Manages purchased upgrades and applies their effects to gameplay.
## Autoload: UpgradeManager

signal upgrade_purchased(upgrade_id: String)

const UPGRADES_PATH := "res://data/upgrades.json"
const SAVE_PATH := "user://upgrades.cfg"

var upgrade_defs: Array = []          # Loaded from JSON
var purchased_upgrades: Dictionary = {}  # { upgrade_id: purchase_count }

# Computed values (updated when upgrades change)
var machine_speed: float = 10.0       # Base 10s, reduced by upgrade
var money_per_customer: int = 10      # Base $10, increased by upgrade
var extra_washers: int = 0
var extra_dryers: int = 0
var extra_ironers: int = 0
var extra_shelves: int = 0

func _ready() -> void:
	_load_upgrade_definitions()
	_load_purchased()
	_recalculate_effects()

func _load_upgrade_definitions() -> void:
	if not FileAccess.file_exists(UPGRADES_PATH):
		push_error("UpgradeManager: upgrades.json not found")
		return
	var file = FileAccess.open(UPGRADES_PATH, FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	if json and json.has("upgrades"):
		upgrade_defs = json["upgrades"]
	print("[UpgradeManager] Loaded %d upgrade definitions" % upgrade_defs.size())

func _load_purchased() -> void:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		for key in config.get_section_keys("purchased"):
			purchased_upgrades[key] = config.get_value("purchased", key, 0)
	print("[UpgradeManager] Loaded %d purchased upgrades" % purchased_upgrades.size())

func _save_purchased() -> void:
	var config = ConfigFile.new()
	for upgrade_id in purchased_upgrades.keys():
		config.set_value("purchased", upgrade_id, purchased_upgrades[upgrade_id])
	config.save(SAVE_PATH)

func _recalculate_effects() -> void:
	# Reset to base values
	machine_speed = 10.0
	money_per_customer = 10
	extra_washers = 0
	extra_dryers = 0
	extra_ironers = 0
	extra_shelves = 0

	for upgrade_id in purchased_upgrades.keys():
		var count: int = purchased_upgrades[upgrade_id]
		if count <= 0:
			continue
		var def = get_upgrade_def(upgrade_id)
		if def == null:
			continue

		match def.get("effect_type", ""):
			"machine_speed":
				machine_speed = float(def.get("effect_value", 10))
			"money_bonus":
				money_per_customer += int(def.get("effect_value", 0)) * count
			"machine_slot":
				var slot: String = def.get("effect_value", "")
				if slot == "washer_2":
					extra_washers += 1
				elif slot == "dryer_2":
					extra_dryers += 1
				elif slot == "ironer_2":
					extra_ironers += 1
			"shelf_slot":
				extra_shelves += 1

	print("[UpgradeManager] Effects: speed=%.1fs, money=$%d, washers+%d, dryers+%d, ironers+%d, shelves+%d" % [
		machine_speed, money_per_customer, extra_washers, extra_dryers, extra_ironers, extra_shelves
	])

func get_upgrade_def(upgrade_id: String) -> Dictionary:
	for def in upgrade_defs:
		if def.get("id", "") == upgrade_id:
			return def
	return {}

func get_purchase_count(upgrade_id: String) -> int:
	return purchased_upgrades.get(upgrade_id, 0)

func can_purchase(upgrade_id: String) -> bool:
	var def = get_upgrade_def(upgrade_id)
	if def.is_empty():
		return false
	
	# Check cost
	var cost: int = def.get("cost", 0)
	if GameState.money < cost:
		return false
	
	# Check max purchases
	var max_p: int = def.get("max_purchases", 1)
	var current: int = get_purchase_count(upgrade_id)
	if current >= max_p:
		return false
	
	# Check requirements
	var requires: String = def.get("requires", "")
	if requires != "" and get_purchase_count(requires) <= 0:
		return false
	
	return true

func is_maxed(upgrade_id: String) -> bool:
	var def = get_upgrade_def(upgrade_id)
	if def.is_empty():
		return true
	var max_p: int = def.get("max_purchases", 1)
	return get_purchase_count(upgrade_id) >= max_p

func purchase(upgrade_id: String) -> bool:
	if not can_purchase(upgrade_id):
		return false
	
	var def = get_upgrade_def(upgrade_id)
	var cost: int = def.get("cost", 0)
	
	# Deduct money
	GameState.money -= cost
	GameState.emit_signal("money_updated", GameState.money)
	
	# Record purchase
	if not purchased_upgrades.has(upgrade_id):
		purchased_upgrades[upgrade_id] = 0
	purchased_upgrades[upgrade_id] += 1
	
	_save_purchased()
	_recalculate_effects()
	emit_signal("upgrade_purchased", upgrade_id)
	
	print("[UpgradeManager] Purchased '%s' for $%d" % [upgrade_id, cost])
	return true

func reset_all() -> void:
	purchased_upgrades.clear()
	_save_purchased()
	_recalculate_effects()
	print("[UpgradeManager] All upgrades reset")

func get_all_upgrades() -> Array:
	return upgrade_defs.duplicate()
