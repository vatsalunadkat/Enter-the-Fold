extends Node
class_name CustomerSpawner

signal customer_spawned(customer_node: Node)
signal all_customers_done

# Customer scene variants
var customer_scenes = [
	preload("res://scenes/customer.tscn"),
	preload("res://scenes/customer_2.tscn"),
	preload("res://scenes/customer_3.tscn")
]

# Customers per day by difficulty
const CUSTOMERS_PER_DIFFICULTY = {
	0: 2,   # Very Easy
	1: 3,   # Easy
	2: 5,   # Medium
	3: 7,   # Hard
	4: 10   # Very Hard
}

# Time between customer spawns
const SPAWN_INTERVAL_SECONDS = {
	0: 30.0,
	1: 25.0,
	2: 18.0,
	3: 12.0,
	4: 8.0
}

var total_customers: int = 0
var customers_spawned: int = 0
var spawn_timer: Timer

func _ready() -> void:
	randomize()

	# Timer used for delayed spawning
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func start_spawning() -> void:
	var difficulty: int = GameConfig.current_difficulty
	total_customers = CUSTOMERS_PER_DIFFICULTY.get(difficulty, 5)
	customers_spawned = 0
	_schedule_next_spawn()

func get_total_customers() -> int:
	return total_customers

func _schedule_next_spawn() -> void:
	# Stop when all customers are spawned
	if customers_spawned >= total_customers:
		emit_signal("all_customers_done")
		return

	var interval: float = SPAWN_INTERVAL_SECONDS.get(GameConfig.current_difficulty, 18.0)
	spawn_timer.start(interval)

func _on_spawn_timer_timeout() -> void:
	_spawn_customer()

func _spawn_customer() -> void:
	# Pick one customer scene randomly
	var random_index: int = randi() % customer_scenes.size()
	var customer = customer_scenes[random_index].instantiate()

	# Add customer to the parent scene
	get_parent().add_child(customer)

	customers_spawned += 1
	emit_signal("customer_spawned", customer)

	# Schedule next customer
	_schedule_next_spawn()
