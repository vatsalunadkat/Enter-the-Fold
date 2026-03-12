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
var player: CharacterBody2D
var player_home_pos: Vector2

# Marker positions
var entrance_pos: Vector2
var station_positions: Array[Vector2] = []
var counter_pos: Vector2
var shelf_pos: Vector2
var exit_pos: Vector2

# Machine arrays — washers always present; dryers for L2+, ironers for L3+
var washers: Array[Node2D] = []
var dryers: Array[Node2D] = []
var ironers: Array[Node2D] = []
var washer_busy: Array[bool] = [false, false, false]
var dryer_busy: Array[bool] = [false, false, false]
var ironer_busy: Array[bool] = [false, false, false]

# Current level (1 = wash only, 2 = wash+dry, 3 = wash+dry+iron)
var current_level: int = 1

# ─── Per-customer tracking ──────────────────────────────────────────
enum CPhase {
	WALKING_IN,
	AWAITING_PICKUP,
	PLAYER_TO_STATION,       # player walking to station
	PLAYER_TO_WASHER,        # player carrying laundry to washer
	WASHING,
	AWAITING_WASH_COLLECT,
	PLAYER_TO_WASHER_COLLECT, # player walking to washer to collect
	PLAYER_TO_DRYER,         # player carrying to dryer (L2+)
	DRYING,
	AWAITING_DRY_COLLECT,
	PLAYER_TO_DRYER_COLLECT,
	PLAYER_TO_IRONER,        # player carrying to ironer (L3+)
	IRONING,
	AWAITING_IRON_COLLECT,
	PLAYER_TO_IRONER_COLLECT,
	PLAYER_TO_SHELF,         # player carrying clean laundry to shelf
	CUSTOMER_RETURNING,
	WALKING_TO_COUNTER,
	AWAITING_SERVE,
	PLAYER_TO_COUNTER,       # player walking to counter to serve
	LEAVING,
}

var active_customers: Dictionary = {}
var next_cust_id: int = 0

# Queue: when player is busy walking for one customer, others wait
var player_busy: bool = false
var player_queue: Array = []  # Array of Callables

# ─── Day state ──────────────────────────────────────────────────────
var customers_served: int = 0
var money_earned_today: int = 0
var day_running: bool = false
var day_over: bool = false

const MAX_SIMULTANEOUS := {
	0: 1, 1: 2, 2: 3, 3: 3, 4: 3,
}
const SPAWN_DELAY := {
	0: 20.0, 1: 14.0, 2: 10.0, 3: 7.0, 4: 5.0,
}

var spawn_timer: Timer

# ─── Setup ──────────────────────────────────────────────────────────

func _ready() -> void:
	randomize()
	current_level = GameConfig.current_level
	_setup_markers()
	_setup_player()
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
	station_positions = [base_drop, base_drop + Vector2(0, 30), base_drop + Vector2(0, 60)]
	shelf_pos = markers.get_node("ShelfSlot_1").position
	counter_pos = markers.get_node("PickupCounter").position
	exit_pos = entrance_pos + Vector2(-60, 0)

func _setup_player() -> void:
	player = get_node_or_null("LaundryPlayer")
	if player:
		player_home_pos = player.position

func _setup_machines() -> void:
	var existing = $Markers.get_node_or_null("WashingMachine")
	if existing:
		existing.queue_free()

	# Washers — always present
	var base_wash := Vector2(-108, -25)
	for i in range(3):
		var wm = washing_machine_scene.instantiate()
		wm.position = base_wash + Vector2(0, i * 30)
		wm.name = "Washer_%d" % i
		wm.set_process_input(false)
		add_child(wm)
		washers.append(wm)

	# Dryers — level 2+
	if current_level >= 2:
		var base_dry := Vector2(-80, -25)
		for i in range(3):
			var dm = washing_machine_scene.instantiate()
			dm.position = base_dry + Vector2(0, i * 30)
			dm.name = "Dryer_%d" % i
			dm.set_process_input(false)
			add_child(dm)
			dryers.append(dm)

	# Ironers — level 3+
	if current_level >= 3:
		var base_iron := Vector2(-52, -25)
		for i in range(3):
			var im = washing_machine_scene.instantiate()
			im.position = base_iron + Vector2(0, i * 30)
			im.name = "Ironer_%d" % i
			im.set_process_input(false)
			add_child(im)
			ironers.append(im)

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
		push_warning("GameHUD not found")

func _setup_timers() -> void:
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.name = "SpawnTimer"
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

# ─── Player movement queue ──────────────────────────────────────────

func _queue_player_action(action: Callable) -> void:
	if player_busy:
		player_queue.append(action)
	else:
		action.call()

func _start_player_walk(target: Vector2, callback: Callable) -> void:
	player_busy = true
	if player == null:
		callback.call()
		_finish_player_action()
		return
	player.walk_to(target)
	player.arrived.connect(func():
		callback.call()
		# Only finish if the callback didn't start another walk
		if not player._walking:
			_finish_player_action()
	, CONNECT_ONE_SHOT)

func _finish_player_action() -> void:
	player_busy = false
	if not player_queue.is_empty():
		var next_action: Callable = player_queue.pop_front()
		next_action.call()

# ─── Day lifecycle ──────────────────────────────────────────────────

func _start_day() -> void:
	customers_served = 0
	money_earned_today = 0
	# In endless mode, keep accumulated money; in regular levels, reset
	if not GameConfig.endless_mode:
		GameState.money = 0
	day_running = true
	day_over = false
	day_timer.start_day()
	_update_hud_task("The day begins!")
	_update_hud_money()
	_update_hud_customers()
	var level_desc := "Wash only"
	if current_level == 2: level_desc = "Wash + Dry"
	elif current_level == 3: level_desc = "Wash + Dry + Iron"
	var mode_str := " (Endless Day %d)" % GameConfig.endless_day if GameConfig.endless_mode else ""
	print("[Game] Level %d (%s)%s — difficulty %d" % [current_level, level_desc, mode_str, GameConfig.current_difficulty])
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
	var washer_idx: int = _find_free_idx(washer_busy)
	if washer_idx == -1: washer_idx = 0

	var cdata := {
		"node": cust,
		"phase": CPhase.WALKING_IN,
		"station_idx": station_idx,
		"washer_idx": washer_idx,
		"dryer_idx": -1,
		"ironer_idx": -1,
		"return_timer": null,
	}
	active_customers[cid] = cdata
	cust.arrived.connect(_on_cust_arrived.bind(cid), CONNECT_ONE_SHOT)
	cust.walk_to(station_positions[station_idx])

func _find_free_station() -> int:
	var used := {}
	for cdata in active_customers.values():
		if cdata["station_idx"] >= 0:
			used[cdata["station_idx"]] = true
	for i in range(station_positions.size()):
		if not used.has(i):
			return i
	return randi() % station_positions.size()

func _find_free_idx(busy_arr: Array) -> int:
	for i in range(busy_arr.size()):
		if not busy_arr[i]:
			return i
	return -1

# ─── Phase transitions ──────────────────────────────────────────────

func _on_cust_arrived(cid: int) -> void:
	if not active_customers.has(cid): return
	var cd = active_customers[cid]
	cd["phase"] = CPhase.AWAITING_PICKUP
	cd["node"].start_idle()
	var anchor = _make_anchor(station_positions[cd["station_idx"]])
	var word = _get_word()
	prompt_manager.show_prompt(word, anchor, "pickup_%d" % cid)
	_update_hud_task("Type '%s' to pick up laundry!" % word)

func _on_prompt_completed(state_id: String) -> void:
	var parts = state_id.split("_")
	if parts.size() < 2: return
	var action = parts[0]
	var cid = int(parts[parts.size() - 1])
	if not active_customers.has(cid): return

	match action:
		"pickup":
			_begin_pickup(cid)
		"washcollect":
			_begin_wash_collect(cid)
		"drycollect":
			_begin_dry_collect(cid)
		"ironcollect":
			_begin_iron_collect(cid)
		"serve":
			_begin_serve(cid)

# ── PICKUP: player walks to station, then to washer ──

func _begin_pickup(cid: int) -> void:
	var cd = active_customers[cid]
	cd["phase"] = CPhase.PLAYER_TO_STATION
	cd["node"].leave_to(exit_pos)
	_queue_player_action(func(): _player_walk_to_station(cid))

func _player_walk_to_station(cid: int) -> void:
	if not active_customers.has(cid): _finish_player_action(); return
	var cd = active_customers[cid]
	_update_hud_task("Walking to pick up laundry...")
	_start_player_walk(station_positions[cd["station_idx"]], func(): _player_walk_to_washer(cid))

func _player_walk_to_washer(cid: int) -> void:
	if not active_customers.has(cid): _finish_player_action(); return
	var cd = active_customers[cid]
	cd["phase"] = CPhase.PLAYER_TO_WASHER
	var wi: int = cd["washer_idx"]
	washer_busy[wi] = true
	_update_hud_task("Carrying laundry to washer %d..." % (wi + 1))
	_start_player_walk(washers[wi].position, func(): _start_washing(cid))

func _start_washing(cid: int) -> void:
	if not active_customers.has(cid): return
	var cd = active_customers[cid]
	cd["phase"] = CPhase.WASHING
	var wi: int = cd["washer_idx"]
	var wash_time: float = UpgradeManager.machine_speed
	_update_hud_task("Washer %d running... (%.0fs)" % [wi + 1, wash_time])
	washers[wi].wash_complete.connect(_on_wash_done.bind(cid), CONNECT_ONE_SHOT)
	washers[wi].start_wash(wash_time)

func _on_wash_done(cid: int) -> void:
	if not active_customers.has(cid): return
	var cd = active_customers[cid]
	cd["phase"] = CPhase.AWAITING_WASH_COLLECT
	var wi: int = cd["washer_idx"]
	washer_busy[wi] = false
	var anchor = _make_anchor(washers[wi].position)
	var word = _get_word()
	prompt_manager.show_prompt(word, anchor, "washcollect_%d" % cid)
	_update_hud_task("Washer %d done! Type '%s'" % [wi + 1, word])

# ── WASH COLLECT → next stage ──

func _begin_wash_collect(cid: int) -> void:
	var cd = active_customers[cid]
	cd["phase"] = CPhase.PLAYER_TO_WASHER_COLLECT
	_queue_player_action(func(): _player_collect_washer(cid))

func _player_collect_washer(cid: int) -> void:
	if not active_customers.has(cid): _finish_player_action(); return
	var cd = active_customers[cid]
	var wi: int = cd["washer_idx"]
	washers[wi].collect_laundry()
	_update_hud_task("Collecting washed laundry...")
	_start_player_walk(washers[wi].position, func(): _after_wash_collect(cid))

func _after_wash_collect(cid: int) -> void:
	if not active_customers.has(cid): return
	if current_level >= 2:
		_player_carry_to_dryer(cid)
	else:
		_player_carry_to_shelf(cid)

# ── DRYING (Level 2+) ──

func _player_carry_to_dryer(cid: int) -> void:
	if not active_customers.has(cid): _finish_player_action(); return
	var cd = active_customers[cid]
	var di: int = _find_free_idx(dryer_busy)
	if di == -1: di = 0
	cd["dryer_idx"] = di
	dryer_busy[di] = true
	cd["phase"] = CPhase.PLAYER_TO_DRYER
	_update_hud_task("Carrying to dryer %d..." % (di + 1))
	_start_player_walk(dryers[di].position, func(): _start_drying(cid))

func _start_drying(cid: int) -> void:
	if not active_customers.has(cid): return
	var cd = active_customers[cid]
	cd["phase"] = CPhase.DRYING
	var di: int = cd["dryer_idx"]
	var dry_time: float = UpgradeManager.machine_speed
	_update_hud_task("Dryer %d running... (%.0fs)" % [di + 1, dry_time])
	dryers[di].wash_complete.connect(_on_dry_done.bind(cid), CONNECT_ONE_SHOT)
	dryers[di].start_wash(dry_time)

func _on_dry_done(cid: int) -> void:
	if not active_customers.has(cid): return
	var cd = active_customers[cid]
	cd["phase"] = CPhase.AWAITING_DRY_COLLECT
	var di: int = cd["dryer_idx"]
	dryer_busy[di] = false
	var anchor = _make_anchor(dryers[di].position)
	var word = _get_word()
	prompt_manager.show_prompt(word, anchor, "drycollect_%d" % cid)
	_update_hud_task("Dryer %d done! Type '%s'" % [di + 1, word])

func _begin_dry_collect(cid: int) -> void:
	var cd = active_customers[cid]
	cd["phase"] = CPhase.PLAYER_TO_DRYER_COLLECT
	_queue_player_action(func(): _player_collect_dryer(cid))

func _player_collect_dryer(cid: int) -> void:
	if not active_customers.has(cid): _finish_player_action(); return
	var cd = active_customers[cid]
	var di: int = cd["dryer_idx"]
	dryers[di].collect_laundry()
	_update_hud_task("Collecting dried laundry...")
	_start_player_walk(dryers[di].position, func(): _after_dry_collect(cid))

func _after_dry_collect(cid: int) -> void:
	if not active_customers.has(cid): return
	if current_level >= 3:
		_player_carry_to_ironer(cid)
	else:
		_player_carry_to_shelf(cid)

# ── IRONING (Level 3+) ──

func _player_carry_to_ironer(cid: int) -> void:
	if not active_customers.has(cid): _finish_player_action(); return
	var cd = active_customers[cid]
	var ii: int = _find_free_idx(ironer_busy)
	if ii == -1: ii = 0
	cd["ironer_idx"] = ii
	ironer_busy[ii] = true
	cd["phase"] = CPhase.PLAYER_TO_IRONER
	_update_hud_task("Carrying to ironer %d..." % (ii + 1))
	_start_player_walk(ironers[ii].position, func(): _start_ironing(cid))

func _start_ironing(cid: int) -> void:
	if not active_customers.has(cid): return
	var cd = active_customers[cid]
	cd["phase"] = CPhase.IRONING
	var ii: int = cd["ironer_idx"]
	var iron_time: float = UpgradeManager.machine_speed
	_update_hud_task("Ironer %d running... (%.0fs)" % [ii + 1, iron_time])
	ironers[ii].wash_complete.connect(_on_iron_done.bind(cid), CONNECT_ONE_SHOT)
	ironers[ii].start_wash(iron_time)

func _on_iron_done(cid: int) -> void:
	if not active_customers.has(cid): return
	var cd = active_customers[cid]
	cd["phase"] = CPhase.AWAITING_IRON_COLLECT
	var ii: int = cd["ironer_idx"]
	ironer_busy[ii] = false
	var anchor = _make_anchor(ironers[ii].position)
	var word = _get_word()
	prompt_manager.show_prompt(word, anchor, "ironcollect_%d" % cid)
	_update_hud_task("Ironer %d done! Type '%s'" % [ii + 1, word])

func _begin_iron_collect(cid: int) -> void:
	var cd = active_customers[cid]
	cd["phase"] = CPhase.PLAYER_TO_IRONER_COLLECT
	_queue_player_action(func(): _player_collect_ironer(cid))

func _player_collect_ironer(cid: int) -> void:
	if not active_customers.has(cid): _finish_player_action(); return
	var cd = active_customers[cid]
	var ii: int = cd["ironer_idx"]
	ironers[ii].collect_laundry()
	_update_hud_task("Collecting ironed laundry...")
	_start_player_walk(ironers[ii].position, func(): _player_carry_to_shelf(cid))

# ── SHELF → CUSTOMER RETURN ──

func _player_carry_to_shelf(cid: int) -> void:
	if not active_customers.has(cid): _finish_player_action(); return
	var cd = active_customers[cid]
	cd["phase"] = CPhase.PLAYER_TO_SHELF
	_update_hud_task("Carrying laundry to shelf...")
	_start_player_walk(shelf_pos, func(): _laundry_shelved(cid))

func _laundry_shelved(cid: int) -> void:
	if not active_customers.has(cid): return
	var cd = active_customers[cid]
	cd["phase"] = CPhase.CUSTOMER_RETURNING
	_update_hud_task("Laundry shelved! Customer returning in 5s...")

	var rt = Timer.new()
	rt.one_shot = true
	rt.name = "ReturnTimer_%d" % cid
	add_child(rt)
	cd["return_timer"] = rt
	rt.timeout.connect(_on_return_timer.bind(cid), CONNECT_ONE_SHOT)
	rt.start(5.0)

func _on_return_timer(cid: int) -> void:
	if not active_customers.has(cid): return
	var cd = active_customers[cid]
	if cd["return_timer"] and is_instance_valid(cd["return_timer"]):
		cd["return_timer"].queue_free()
	cd["return_timer"] = null
	cd["phase"] = CPhase.WALKING_TO_COUNTER

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
	if not active_customers.has(cid): return
	var cd = active_customers[cid]
	cd["phase"] = CPhase.AWAITING_SERVE
	cd["node"].start_idle()
	var anchor = _make_anchor(counter_pos + Vector2(0, -10))
	var word = _get_word()
	prompt_manager.show_prompt(word, anchor, "serve_%d" % cid)
	_update_hud_task("Type '%s' to serve customer!" % word)

# ── SERVE ──

func _begin_serve(cid: int) -> void:
	var cd = active_customers[cid]
	cd["phase"] = CPhase.PLAYER_TO_COUNTER
	_queue_player_action(func(): _player_walk_to_counter(cid))

func _player_walk_to_counter(cid: int) -> void:
	if not active_customers.has(cid): _finish_player_action(); return
	_update_hud_task("Walking to counter...")
	_start_player_walk(counter_pos, func(): _serve_customer(cid))

func _serve_customer(cid: int) -> void:
	if not active_customers.has(cid): return
	var cd = active_customers[cid]
	cd["phase"] = CPhase.LEAVING

	var reward := UpgradeManager.money_per_customer
	GameState.add_money(reward)
	money_earned_today += reward
	customers_served += 1
	_update_hud_money()
	_update_hud_customers()
	_update_hud_task("$%d earned!" % reward)

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
