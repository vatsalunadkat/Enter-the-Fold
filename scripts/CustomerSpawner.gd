extends Node
class_name CustomerSpawner

signal customer_spawned(customer_node: Node)
signal all_customers_done

var customer_scenes = [
	preload("res://scenes/customer.tscn"),
	preload("res://scenes/customer_2.tscn"),
	preload("res://scenes/customer_3.tscn")
]

const CUSTOMERS_PER_DIFFICULTY = {
	0: 2,
	1: 3,
	2: 5,
	3: 7,
	4: 10
}

const SPAWN_INTERVAL_SECONDS = {
	0: 1.0,
	1: 1.0,
	2: 1.0,
	3: 1.0,
	4: 1.0
}

var total_customers: int = 0
var customers_spawned: int = 0
var spawn_timer: Timer

func _ready() -> void:
	randomize()

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
	if customers_spawned >= total_customers:
		emit_signal("all_customers_done")
		return

	var interval: float = SPAWN_INTERVAL_SECONDS.get(GameConfig.current_difficulty, 1.0)
	spawn_timer.start(interval)

func _on_spawn_timer_timeout() -> void:
	_spawn_customer()

func _spawn_customer() -> void:
	var random_index: int = randi() % customer_scenes.size()
	var customer = customer_scenes[random_index].instantiate()

	customers_spawned += 1
	customer.name = "Customer_%d" % customers_spawned

	get_parent().add_child(customer)

	print("Spawned customer: ", customers_spawned)

	emit_signal("customer_spawned", customer)

	_schedule_next_spawn()
