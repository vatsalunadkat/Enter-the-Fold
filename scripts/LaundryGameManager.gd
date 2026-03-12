extends Node2D

# ─── Preloads ───────────────────────────────────────────────────────
var customer_scenes = [
	preload("res://scenes/customer.tscn"),
	preload("res://scenes/customer_2.tscn"),
	preload("res://scenes/customer_3.tscn"),
]
var washing_machine_scene = preload("res://scenes/washing_machine.tscn")
var prompt_manager_scene = preload("res://scenes/PromptManager.tscn")

# ─── Node references (populated in _ready) ─────────────────────────
var hud: CanvasLayer
var prompt_manager: Node2D
var day_timer: Node

# Marker positions (from the Markers child group)
var entrance_pos: Vector2
var station_positions: Array[Vector2] = []   # 3 drop-off stations
var machine_positions: Array[Vector2] = []   # 3 washing machine slots
var shelf_pos: Vector2
var counter_pos: Vector2
var exit_pos: Vector2

# Washing machine nodes
var machines: Array[Node2D] = []
var machine_busy: Array[bool] = [false, false, false]

# ─── Game state ─────────────────────────────────────────────────────
enum Phase {
	WAITING_ARRIVAL,        # Waiting for next customer to spawn
	CUSTOMER_WALKING_IN,    # Customer walking to drop-off station
	AWAITING_PICKUP,        # Prompt above station — type to pick up laundry
	MACHINE_WASHING,        # Machine running for 10 seconds
	AWAITING_MACHINE_COLLECT, # Prompt above machine — type to collect clean laundry
	CUSTOMER_RETURNING,     # 5-second wait for customer to walk back in
	AWAITING_SERVE,         # Prompt above customer — type to serve & collect $
	CUSTOMER_LEAVING,       # Customer walking out after being served
}

var phase: Phase = Phase.WAITING_ARRIVAL
var current_customer: CharacterBody2D = null
var assigned_station_idx: int = -1
var assigned_machine_idx: int = -1
var customers_served: int = 0
var total_customers: int = 0
var day_running: bool = false
var money_earned_today: int = 0

# Customers per difficulty
const CUSTOMERS_PER_DIFFICULTY := {
	0: 2,   # Very Easy
	1: 3,   # Easy
	2: 5,   # Medium
	3: 7,   # Hard
	4: 10,  # Very Hard
}
# Seconds between customer arrivals per difficulty
const SPAWN_DELAY := {
	0: 25.0,
	1: 18.0,
	2: 12.0,
	3: 9.0,
	4: 6.0,
}

var spawn_timer: Timer
var return_timer: Timer

# ─── Setup ──────────────────────────────────────────────────────────

func _ready() -> void:
	randomize()
	_setup_markers()
	_setup_machines()
	_setup_prompt_manager()
	_setup_day_timer()
	_setup_hud()
	_setup_timers()
	_start_day()

func _setup_markers() -> void:
	var markers = $Markers
	entrance_pos = markers.get_node("CustomerEntrance").position

	# 3 stations: use DropOffPoint plus offsets (spread along y)
	var base_drop = markers.get_node("DropOffPoint").position
	station_positions = [
		base_drop,
		base_drop + Vector2(0, 30),
		base_drop + Vector2(0, 60),
	]

	shelf_pos = markers.get_node("ShelfSlot_1").position
	counter_pos = markers.get_node("PickupCounter").position
	exit_pos = entrance_pos + Vector2(-60, 0)  # walk off screen left

func _setup_machines() -> void:
	# Remove the existing single washing machine from the scene
	var existing_machine = $Markers.get_node_or_null("WashingMachine")
	if existing_machine:
		existing_machine.queue_free()

	# Create 3 washing machines at offsets from the original position
	var base_machine_pos = Vector2(-108, -25)
	var offsets = [Vector2(0, 0), Vector2(0, 30), Vector2(0, 60)]

	for i in range(3):
		var wm = washing_machine_scene.instantiate()
		wm.position = base_machine_pos + offsets[i]
		wm.name = "Machine_%d" % i
		# Remove the test _input handler from washing machines
		wm.set_process_input(false)
		add_child(wm)
		machines.append(wm)
		machine_busy.append(false)

	# Fix array — we initialized with 3 defaults + appended 3 more
	machine_busy = [false, false, false]

func _setup_prompt_manager() -> void:
	prompt_manager = prompt_manager_scene.instantiate()
	prompt_manager.name = "PromptManager"
	add_child(prompt_manager)
	prompt_manager.prompt_completed.connect(_on_prompt_completed)

func _setup_day_timer() -> void:
	day_timer = DayTimer.new()
	day_timer.name = "DayTimer"
	add_child(day_timer)
	day_timer.time_updated.connect(_on_time_updated)
	day_timer.day_ended.connect(_on_day_ended)

func _setup_hud() -> void:
	# HUD is created in the scene tree by LaundryStore.tscn (GameHUD node under UI)
	hud = get_node_or_null("UI/GameHUD")
	if hud == null:
		push_warning("GameHUD not found — HUD updates will be skipped")

func _setup_timers() -> void:
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.name = "SpawnTimer"
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	return_timer = Timer.new()
	return_timer.one_shot = true
	return_timer.name = "ReturnTimer"
	add_child(return_timer)
	return_timer.timeout.connect(_on_return_timer_timeout)

# ─── Day lifecycle ──────────────────────────────────────────────────

func _start_day() -> void:
	var diff: int = GameConfig.current_difficulty
	total_customers = CUSTOMERS_PER_DIFFICULTY.get(diff, 5)
	customers_served = 0
	money_earned_today = 0
	GameState.money = 0
	day_running = true

	day_timer.start_day()
	_update_hud_task("The day begins! Customers incoming...")
	_update_hud_money()
	_update_hud_customers()
	print("[Game] Day started — difficulty %d, %d customers" % [diff, total_customers])

	# Spawn first customer after a short delay
	spawn_timer.start(2.0)

func _end_day() -> void:
	day_running = false
	day_timer.stop()
	prompt_manager.clear_all_prompts()
	_update_hud_task("Day over!")
	print("[Game] Day ended — served %d/%d, earned $%d" % [customers_served, total_customers, money_earned_today])
	_show_end_of_day()

func _show_end_of_day() -> void:
	if hud and hud.has_method("show_day_over"):
		hud.show_day_over(money_earned_today, customers_served, total_customers)

# ─── Customer spawning ──────────────────────────────────────────────

func _on_spawn_timer_timeout() -> void:
	if not day_running:
		return
	if customers_served + (_count_active_customers()) >= total_customers:
		return
	_spawn_next_customer()

func _count_active_customers() -> int:
	return 1 if current_customer != null else 0

func _spawn_next_customer() -> void:
	var scene_idx: int = randi() % customer_scenes.size()
	current_customer = customer_scenes[scene_idx].instantiate()
	current_customer.position = entrance_pos
	add_child(current_customer)

	# Pick a random free station
	assigned_station_idx = randi() % station_positions.size()

	# Pick a free machine
	assigned_machine_idx = _find_free_machine()
	if assigned_machine_idx == -1:
		assigned_machine_idx = 0  # fallback

	phase = Phase.CUSTOMER_WALKING_IN
	_update_hud_task("A customer is arriving...")
	print("[Game] Customer spawned → walking to station %d" % assigned_station_idx)

	current_customer.arrived.connect(_on_customer_arrived_at_station, CONNECT_ONE_SHOT)
	current_customer.walk_to(station_positions[assigned_station_idx])

func _find_free_machine() -> int:
	for i in range(machines.size()):
		if not machine_busy[i]:
			return i
	return -1

# ─── Phase transitions ──────────────────────────────────────────────

func _on_customer_arrived_at_station() -> void:
	phase = Phase.AWAITING_PICKUP
	current_customer.start_idle()

	# Create an anchor node at the station for the prompt
	var anchor = _make_anchor(station_positions[assigned_station_idx])
	var word = prompt_manager.get_random_word("easy")
	prompt_manager.show_prompt(word, anchor, "pickup")
	_update_hud_task("Type '%s' to pick up the laundry!" % word)
	print("[Game] AWAITING_PICKUP — type '%s'" % word)

func _on_prompt_completed(state_id: String) -> void:
	match state_id:
		"pickup":
			_handle_pickup_done()
		"machine_collect":
			_handle_machine_collect_done()
		"serve":
			_handle_serve_done()

func _handle_pickup_done() -> void:
	phase = Phase.MACHINE_WASHING
	machine_busy[assigned_machine_idx] = true

	# Customer leaves after dropping off
	current_customer.leave_to(exit_pos)

	_update_hud_task("Laundry is washing... (10 seconds)")
	print("[Game] MACHINE_WASHING — machine %d started" % assigned_machine_idx)

	# Start the washing machine visuals + timer
	var machine = machines[assigned_machine_idx]
	machine.wash_complete.connect(_on_wash_complete, CONNECT_ONE_SHOT)
	machine.start_wash(10.0)

func _on_wash_complete() -> void:
	phase = Phase.AWAITING_MACHINE_COLLECT
	machine_busy[assigned_machine_idx] = false

	var anchor = _make_anchor(machines[assigned_machine_idx].position)
	var word = prompt_manager.get_random_word("easy")
	prompt_manager.show_prompt(word, anchor, "machine_collect")
	_update_hud_task("Washing done! Type '%s' to collect laundry." % word)
	print("[Game] AWAITING_MACHINE_COLLECT — type '%s'" % word)

func _handle_machine_collect_done() -> void:
	machines[assigned_machine_idx].collect_laundry()
	phase = Phase.CUSTOMER_RETURNING
	_update_hud_task("Laundry on shelf. Customer returning in 5 seconds...")
	print("[Game] CUSTOMER_RETURNING — 5 second wait")
	return_timer.start(5.0)

func _on_return_timer_timeout() -> void:
	if phase != Phase.CUSTOMER_RETURNING:
		return

	# Respawn / re-show the customer at entrance walking to counter
	if current_customer == null or not is_instance_valid(current_customer):
		var scene_idx: int = randi() % customer_scenes.size()
		current_customer = customer_scenes[scene_idx].instantiate()
		add_child(current_customer)

	current_customer.position = entrance_pos
	current_customer.show()
	current_customer.arrived.connect(_on_customer_arrived_at_counter, CONNECT_ONE_SHOT)
	current_customer.walk_to(counter_pos)
	_update_hud_task("Customer is coming to pick up laundry...")

func _on_customer_arrived_at_counter() -> void:
	phase = Phase.AWAITING_SERVE
	current_customer.start_idle()

	var anchor = _make_anchor(counter_pos + Vector2(0, -10))
	var word = prompt_manager.get_random_word("easy")
	prompt_manager.show_prompt(word, anchor, "serve")
	_update_hud_task("Type '%s' to serve the customer!" % word)
	print("[Game] AWAITING_SERVE — type '%s'" % word)

func _handle_serve_done() -> void:
	phase = Phase.CUSTOMER_LEAVING

	# Award money
	var reward := 10
	GameState.add_money(reward)
	money_earned_today += reward
	customers_served += 1

	_update_hud_money()
	_update_hud_customers()
	_update_hud_task("$%d earned! Customer leaving..." % reward)
	print("[Game] MONEY_COLLECTED — $%d (total: $%d, served: %d/%d)" % [reward, money_earned_today, customers_served, total_customers])

	# Customer walks out
	current_customer.left_store.connect(_on_customer_left, CONNECT_ONE_SHOT)
	current_customer.leave_to(exit_pos)

func _on_customer_left() -> void:
	if current_customer and is_instance_valid(current_customer):
		current_customer.queue_free()
	current_customer = null
	phase = Phase.WAITING_ARRIVAL

	if customers_served >= total_customers:
		_end_day()
		return

	if not day_running:
		_end_day()
		return

	# Schedule next customer
	var diff: int = GameConfig.current_difficulty
	var delay: float = SPAWN_DELAY.get(diff, 12.0)
	spawn_timer.start(delay)
	_update_hud_task("Next customer arriving soon...")

# ─── Day timer callbacks ────────────────────────────────────────────

func _on_time_updated(_hour: int, _minute: int) -> void:
	if hud and hud.has_method("update_time"):
		hud.update_time(day_timer.get_time_string())

func _on_day_ended() -> void:
	day_running = false
	# Let the current customer finish if one is being served
	if phase == Phase.WAITING_ARRIVAL:
		_end_day()
	# else: the day will end after the current customer cycle completes

# ─── HUD helpers ────────────────────────────────────────────────────

func _update_hud_task(text: String) -> void:
	if hud and hud.has_method("update_task"):
		hud.update_task(text)

func _update_hud_money() -> void:
	if hud and hud.has_method("update_money"):
		hud.update_money(GameState.money)

func _update_hud_customers() -> void:
	if hud and hud.has_method("update_customers"):
		hud.update_customers(customers_served, total_customers)

# ─── Utilities ──────────────────────────────────────────────────────

func _make_anchor(pos: Vector2) -> Node2D:
	var anchor = Node2D.new()
	anchor.position = pos
	anchor.name = "PromptAnchor"
	add_child(anchor)
	# Clean up anchors when prompts complete
	get_tree().create_timer(30.0).timeout.connect(func():
		if is_instance_valid(anchor):
			anchor.queue_free()
	)
	return anchor
