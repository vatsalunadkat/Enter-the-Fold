extends Control
## Upgrade shop screen shown between days in Endless Mode.
## Allows players to spend money on upgrades before starting the next day.

@onready var money_label: Label = $Panel/VBox/Header/MoneyLabel
@onready var grid: GridContainer = $Panel/VBox/ScrollContainer/Grid
@onready var next_day_btn: Button = $Panel/VBox/Footer/NextDayButton

const CARD_SCENE := preload("res://scenes/UpgradeCard.tscn")

var cards: Dictionary = {}  # upgrade_id -> UpgradeCard node

func _ready() -> void:
	_update_money_display()
	_populate_upgrades()
	next_day_btn.pressed.connect(_on_next_day_pressed)
	UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)
	GameState.money_updated.connect(_on_money_updated)

func _update_money_display() -> void:
	money_label.text = "Balance: $%d" % GameState.money

func _populate_upgrades() -> void:
	# Clear existing cards
	for child in grid.get_children():
		child.queue_free()
	cards.clear()
	
	# Create card for each upgrade
	for def in UpgradeManager.get_all_upgrades():
		var card = CARD_SCENE.instantiate()
		grid.add_child(card)
		card.setup(def)
		cards[def["id"]] = card

func _on_upgrade_purchased(_upgrade_id: String) -> void:
	# Refresh all cards (some may now be unlocked or maxed)
	for upgrade_id in cards.keys():
		cards[upgrade_id].refresh()

func _on_money_updated(_new_total: int) -> void:
	_update_money_display()
	# Refresh all cards to update buy button states
	for upgrade_id in cards.keys():
		cards[upgrade_id].refresh()

func _on_next_day_pressed() -> void:
	# Increment endless day counter
	GameConfig.endless_day += 1
	print("[UpgradeShop] Starting Endless Day %d" % GameConfig.endless_day)
	SceneRouter.go_to("res://scenes/LaundryStore.tscn")
