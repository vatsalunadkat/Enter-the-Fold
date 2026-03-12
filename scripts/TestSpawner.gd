extends Node2D

@onready var label: Label = $Label
@onready var spawner: CustomerSpawner = $CustomerSpawner

func _ready() -> void:
	spawner.customer_spawned.connect(_on_customer_spawned)
	spawner.all_customers_done.connect(_on_all_customers_done)

	spawner.start_spawning()

	var total: int = spawner.get_total_customers()
	label.text = "Total customers today: %d" % total

	print("Difficulty:", GameConfig.current_difficulty)
	print("Expected total customers:", total)

func _on_customer_spawned(customer_node: Node) -> void:
	pass

func _on_all_customers_done() -> void:
	print("All customers done for the day.")
