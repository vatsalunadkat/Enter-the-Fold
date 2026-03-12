extends PanelContainer
## Individual upgrade card in the shop.

@onready var name_label: Label = $VBox/NameLabel
@onready var desc_label: Label = $VBox/DescLabel
@onready var cost_label: Label = $VBox/CostLabel
@onready var buy_button: Button = $VBox/BuyButton
@onready var owned_label: Label = $VBox/OwnedLabel

var upgrade_id: String = ""
var upgrade_def: Dictionary = {}

func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)

func setup(def: Dictionary) -> void:
	upgrade_def = def
	upgrade_id = def.get("id", "")
	
	name_label.text = def.get("name", "Unknown")
	desc_label.text = def.get("description", "")
	cost_label.text = "$%d" % def.get("cost", 0)
	
	refresh()

func refresh() -> void:
	var owned := UpgradeManager.get_purchase_count(upgrade_id)
	var max_p: int = upgrade_def.get("max_purchases", 1)
	var is_maxed := owned >= max_p
	var can_buy := UpgradeManager.can_purchase(upgrade_id)
	
	# Check if locked by requirements
	var requires: String = upgrade_def.get("requires", "")
	var is_locked := requires != "" and UpgradeManager.get_purchase_count(requires) <= 0
	
	if is_maxed:
		owned_label.text = "✓ Owned" if max_p == 1 else "✓ Owned (%d/%d)" % [owned, max_p]
		owned_label.visible = true
		buy_button.visible = false
		modulate.a = 0.7
	elif is_locked:
		owned_label.text = "🔒 Requires: %s" % _get_upgrade_name(requires)
		owned_label.visible = true
		buy_button.visible = false
		modulate.a = 0.5
	else:
		if owned > 0 and max_p > 1:
			owned_label.text = "Owned: %d/%d" % [owned, max_p]
			owned_label.visible = true
		else:
			owned_label.visible = false
		buy_button.visible = true
		buy_button.disabled = not can_buy
		buy_button.text = "Buy" if can_buy else "Not enough $"
		modulate.a = 1.0

func _get_upgrade_name(uid: String) -> String:
	var def = UpgradeManager.get_upgrade_def(uid)
	return def.get("name", uid)

func _on_buy_pressed() -> void:
	UpgradeManager.purchase(upgrade_id)
