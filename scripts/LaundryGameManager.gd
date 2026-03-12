extends Node2D

# ─── Preloads ───────────────────────────────────────────────────────
var customer_scenes = [
	preload("res://scenes/customer.tscn"),
	preload("res://scenes/customer_2.tscn"),
	preload("res://scenes/customer_3.tscn"),
]
var washing_machine_scene = preload("res://scenes/washing_machine.tscn")
var prompt_manager_scene = preload("res://scenes/PromptManager.tscn")

# ─── Node references ───────────────────────────────────────────────
var hud: CanvasLayer
var prompt_manager: Node2D
var day_timer: Node

# Marker positions
var entrance_pos: Vector2
var station_positions: Array[Vector2] = []   # 3 drop-off stations
var counter_pos: Vector2
var shelf_pos: Vector2
var exit_pos: Vector2

# Washing machine nodes
var machines: Array[Node2D] = []
var machine_busy: Array[bool] = [false, false, false]

# ─── Per-customer tracking ──────────────────────────────────────────
# Each active customer is tracked in a dictionary keyed by a unique id.
# Value: { node, phase, station_idx, machine_idx, return_timer }
enum CPhase {
	WALKING_IN,
	AWAITING_PICKUP,
	MACHINE_WASHING,
	AWAITING_MACHINE_COLLECT,
	CUSTOMER_RETURNING,
	WALKING_TO_COUNTER,
	AWAITING_SERVE,
	LEAVING,
}

var active_customers: Dictionary = {}  # id -> dict
var next_cust_id: int = 0

# ─── Day state ──────────────────────────────────────────────────────
var customers_served: int = 0
var money_earned_today: int = 0
var day_running: bool = false
var day_over: bool = false

# Max simultaneous customers on screen — scales with difficulty
const MAX_SIMULTANEOUS := {
	0: 1,   # Very Easy
	1: 2,   # Easy
	2: 3,   # Medium
	3: 3,   # Hard
	4: 3,   # Very Hard
}
# Spawn delay between customer arrivals
const SPAWN_DELAY := {
	0: 20.0,
	1: 14.0,
	2: 10.0,
	3: 7.0,
	4: 5.0,
}

var spawn_timer: Timer

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

	var base_drop = markers.get_node("DropOffPoint").position
	station_positions = [
		base_drop,
		base_drop + Vector2(0, 30),
		base_drop + Vector2(0, 60),
	]

	shelf_pos = markers.get_node("ShelfSlot_1").position
	counter_pos = markers.get_node("PickupCounter").position
	exit_pos = entrance_pos + Vector2(-60, 0)

func _setup_machines() -> void:
	var existing_machine = $Markers.get_node_or_null("WashingMachine")
	if existing_machine:
		existing_machine.queue_free()

	var base_machine_pos = Vector2(-108, -25)
	var offsets = [Vector2(0, 0), Vector2(0, 30), Vector2(0, 60)]

	for i in range(3):
		var wm = washing_machine_scene.instantiate()
		wm.position = base_machine_pos + offsets[i]
		wm.name = "Machine_%d" % i
		wm.set_process_input(false)
		add_child(wm)
		machines.append(wm)

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
	hud = get_node_or_null("UI/GameHUD")
	if hud == null:
		push_warning("GameHUD not found — HUD updates will be skipped")

func _setup_timers() -> void:
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.name = "SpawnTimer"
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

# ─── Day lifecycle ──────────────────────────────────────────────────

func _start_day() -> void:
	customers_served = 0
	money_earned_today = 0
	GameState.money = 0
	day_running = true
	day_over = false

	day_timer.start_day()
	_update_hud_task("The day begins!")
	_update_hud_money()
	_update_hud_customers()
	print("[Game] Day started — difficulty %d" % GameConfig.current_difficulty)

	spawn_timer.start(1.5)

func _end_day() -> void:
	if day_over:
		return
	day_over = true
	day_running = false
	spawn_timer.stop()
	day_timer.stop()
	prompt_manager.clear_all_prompts()
	_update_hud_task("Day over!")
	print("[Game] Day ended — served %d, earned $%d" % [customers_served, money_earned_today])
	_show_end_of_day()

func _show_end_of_day() -> void:
	if hud and hud.has_method("show_day_over"):
		hud.show_day_over(money_earned_today, customers_served)

func _check_day_over() -> void:
	if not day_running and not day_over and active_customers.is_empty():
		_end_day()

# ─── Customer spawning ──────────────────────────────────────────────

func _on_spawn_timer_timeout() -> void:
	if not day_running:
		return
	var max_sim: int = MAX_SIMULTANEOUS.get(GameConfig.current_difficulty, 3)
	if active_customers.size() < max_sim:
		_spawn_customer()
	# Schedule next attempt
	if day_running:
		var delay: float = SPAWN_DELAY.get(GameConfig.current_difficulty, 10.0)
		spawn_timer.start(delay)

func _spawn_customer() -> void:
	var cid: int = next_cust_id
	next_cust_id += 1

	var scene_idx: int = randi() % customer_scenes.size()
	var cust = customer_scenes[scene_idx].instantiate()
	cust.position = entrance_pos
	cust.scale = Vector2(0.3, 0.3)
	cust.name = "Customer_%d" % cid
	add_child(cust)

	var station_idx: int = _find_free_station()
	var machine_idx: int = _find_free_machine()
	if machine_idx == -1:
		machine_idx = 0

	var cdata := {
		"node": cust,
		"phase": CPhase.WALKING_IN,
		"station_idx": station_idx,
		"machine_idx": machine_idx,
		"return_timer": null,
	}
	active_customers[cid] = cdata

	cust.arrived.connect(_on_cust_arrived.bind(cid), CONNECT_ONE_SHOT)
	cust.walk_to(station_positions[station_idx])
	print("[Game] Customer %d spawned → station %d" % [cid, station_idx])

func _find_free_station() -> int:
	var used := {}
	for cdata in active_customers.values():
		if cdata["station_idx"] >= 0:
			used[cdata["station_idx"]] = true
	for i in range(station_positions.size()):
		if not used.has(i):
			return i
	return randi() % station_positions.size()

func _find_free_machine() -> int:
	for i in range(machines.size()):
		if not machine_busy[i]:
			return i
	return -1

# ─── Phase transitions ──────────────────────────────────────────────

func _on_cust_arrived(cid: int) -> void:
	if not active_customers.has(cid):
		return
	var cd = active_customers[cid]
	cd["phase"] = CPhase.AWAITING_PICKUP
	cd["node"].start_idle()

	var anchor = _make_anchor(station_positions[cd["station_idx"]])
	var word = _get_word()
	var prompt_id = "pickup_%d" % cid
	prompt_manager.show_prompt(word, anchor, prompt_id)
	_update_hud_task("Type '%s' to pick up laundry!" % word)
	print("[Game] Customer %d: AWAITING_PICKUP — '%s'" % [cid, word])

func _on_prompt_completed(state_id: String) -> void:
	var parts = state_id.split("_")
	if parts.size() < 2:
		return
	var action = parts[0]
	var cid = int(parts[parts.size() - 1])  # last part is the id

	if not active_customers.has(cid):
		return

	match action:
		"pickup":
			_handle_pickup_done(cid)
		"collect":
			_handle_machine_collect_done(cid)
		"serve":
			_handle_serve_done(cid)

func _handle_pickup_done(cid: int) -> void:
	var cd = active_customers[cid]
	cd["phase"] = CPhase.MACHINE_WASHING

	var mi: int = cd["machine_idx"]
	machine_busy[mi] = true

	# Customer leaves store after drop-off
	cd["node"].leave_to(exit_pos)

	_update_hud_task("Machine %d washing... (10 seconds)" % (mi + 1))
	print("[Game] Customer %d: MACHINE_WASHING on machine %d" % [cid, mi])

	var machine = machines[mi]
	machine.wash_complete.connect(_on_wash_complete.bind(cid), CONNECT_ONE_SHOT)
	machine.start_wash(10.0)

func _on_wash_complete(cid: int) -> void:
	if not active_customers.has(cid):
		return
	var cd = active_customers[cid]
	cd["phase"] = CPhase.AWAITING_MACHINE_COLLECT

	var mi: int = cd["machine_idx"]
	machine_busy[mi] = false

	var anchor = _make_anchor(machines[mi].position)
	var word = _get_word()
	var prompt_id = "collect_%d" % cid
	prompt_manager.show_prompt(word, anchor, prompt_id)
	_update_hud_task("Machine %d done! Type '%s'" % [mi + 1, word])
	print("[Game] Customer %d: AWAITING_MACHINE_COLLECT — '%s'" % [cid, word])

func _handle_machine_collect_done(cid: int) -> void:
	var cd = active_customers[cid]
	machines[cd["machine_idx"]].collect_laundry()
	cd["phase"] = CPhase.CUSTOMER_RETURNING
	_update_hud_task("Laundry shelved! Customer returning in 5s...")
	print("[Game] Customer %d: CUSTOMER_RETURNING in 5s" % cid)

	var rt = Timer.new()
	rt.one_shot = true
	rt.name = "ReturnTimer_%d" % cid
	add_child(rt)
	cd["return_timer"] = rt
	rt.timeout.connect(_on_return_timer.bind(cid), CONNECT_ONE_SHOT)
	rt.start(5.0)

func _on_return_timer(cid: int) -> void:
	if not active_customers.has(cid):
		return
	var cd = active_customers[cid]

	# Clean up timer
	if cd["return_timer"] and is_instance_valid(cd["return_timer"]):
		cd["return_timer"].queue_free()
	cd["return_timer"] = null

	cd["phase"] = CPhase.WALKING_TO_COUNTER

	# Re-show or re-instantiate customer
	var cust = cd["node"]
	if cust == null or not is_instance_valid(cust):
		var scene_idx: int = randi() % customer_scenes.size()
		cust = customer_scenes[scene_idx].instantiate()
		cust.scale = Vector2(0.3, 0.3)
		cust.name = "Customer_%d_return" % cid
		add_child(cust)
		cd["node"] = cust

	cust.position = entrance_pos
	cust.show()
	cust.arrived.connect(_on_cust_at_counter.bind(cid), CONNECT_ONE_SHOT)
	cust.walk_to(counter_pos)
	_update_hud_task("Customer coming to pick up laundry...")

func _on_cust_at_counter(cid: int) -> void:
	if not active_customers.has(cid):
		return
	var cd = active_customers[cid]
	cd["phase"] = CPhase.AWAITING_SERVE
	cd["node"].start_idle()

	var anchor = _make_anchor(counter_pos + Vector2(0, -10))
	var word = _get_word()
	var prompt_id = "serve_%d" % cid
	prompt_manager.show_prompt(word, anchor, prompt_id)
	_update_hud_task("Type '%s' to serve customer!" % word)
	print("[Game] Customer %d: AWAITING_SERVE — '%s'" % [cid, word])

func _handle_serve_done(cid: int) -> void:
	var cd = active_customers[cid]
	cd["phase"] = CPhase.LEAVING

	var reward := 10
	GameState.add_money(reward)
	money_earned_today += reward
	customers_served += 1

	_update_hud_money()
	_update_hud_customers()
	_update_hud_task("$%d earned!" % reward)
	print("[Game] Customer %d: SERVED — $%d (total $%d)" % [cid, reward, money_earned_today])

	cd["node"].left_store.connect(_on_cust_left.bind(cid), CONNECT_ONE_SHOT)
	cd["node"].leave_to(exit_pos)
	_check_day_over()

func _on_cust_left(cid: int) -> void:
	if active_customers.has(cid):
		var cd = active_customers[cid]
		if cd["node"] and is_instance_valid(cd["node"]):
			cd["node"].queue_free()
		active_customers.erase(cid)

	_check_day_over()

# ─── Day timer callbacks ────────────────────────────────────────────

func _on_time_updated(_hour: int, _minute: int) -> void:
	if hud and hud.has_method("update_time"):
		hud.update_time(day_timer.get_time_string())

func _on_day_ended() -> void:
	day_running = false
	spawn_timer.stop()
	if active_customers.is_empty():
		_end_day()
	else:
		_update_hud_task("Store closing! Finish serving remaining customers...")

# ─── HUD helpers ────────────────────────────────────────────────────

func _update_hud_task(text: String) -> void:
	if hud and hud.has_method("update_task"):
		hud.update_task(text)

func _update_hud_money() -> void:
	if hud and hud.has_method("update_money"):
		hud.update_money(GameState.money)

func _update_hud_customers() -> void:
	if hud and hud.has_method("update_customers"):
		hud.update_customers(customers_served)

# ─── Utilities ──────────────────────────────────────────────────────

func _get_word() -> String:
	var diff_key: String = "easy"
	var wd: int = GameConfig.word_difficulty
	match wd:
		0: diff_key = "letters"
		1: diff_key = "easy"
		2: diff_key = "easy"
		3: diff_key = "medium"
		4: diff_key = "hard"
	return prompt_manager.get_random_word(diff_key)

func _make_anchor(pos: Vector2) -> Node2D:
	var anchor = Node2D.new()
	anchor.position = pos
	anchor.name = "PromptAnchor"
	add_child(anchor)
	get_tree().create_timer(60.0).timeout.connect(func():
		if is_instance_valid(anchor):
			anchor.queue_free()
	)
	return anchor
