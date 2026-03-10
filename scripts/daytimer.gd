extends Node
class_name DayTimer

signal time_updated(hour: int, minute: int)   # Emitted every game-minute
signal day_ended                               # Emitted when clock hits 20:00 (8pm)

var game_hour   : int   = 8
var game_minute : int   = 0
var is_running  : bool  = false
var elapsed_real_seconds : float = 0.0

const REAL_SECONDS_PER_GAME_MINUTE := 0.25   # 180 seconds / 720 game-minutes
const START_HOUR := 8
const END_HOUR   := 20   # 8pm in 24h format

# resets everything back to 8:00 AM and starts the clock ticking.
# call this at the start of each new in-game day.

func start_day() -> void:
	game_hour            = START_HOUR
	game_minute          = 0
	elapsed_real_seconds = 0.0
	is_running           = true
	emit_signal("time_updated", game_hour, game_minute)

# freezes clock
func stop() -> void:
	is_running = false


func resume() -> void:
	# only resume if the day hasn't ended yet
	if game_hour < END_HOUR:
		is_running = true

# returns the current time as a string 
func get_time_string() -> String:
	var display_hour : int = game_hour % 12
	if display_hour == 0:
		display_hour = 12
	var ampm : String = "AM" if game_hour < 12 else "PM"
	return "%d:%02d %s" % [display_hour, game_minute, ampm]


func get_progress() -> float:
	# returns 0.0 (8:00 AM) → 1.0 (8:00 PM) for progress bars
	var total_minutes_elapsed : int = (game_hour - START_HOUR) * 60 + game_minute
	return clamp(float(total_minutes_elapsed) / 720.0, 0.0, 1.0)


func _process(delta: float) -> void:
	if not is_running:
		return

	elapsed_real_seconds += delta

	if elapsed_real_seconds >= REAL_SECONDS_PER_GAME_MINUTE:
		elapsed_real_seconds -= REAL_SECONDS_PER_GAME_MINUTE
		advance_minute()

# increments the clock by one game-minute, rolls over to the next hour
# at 60 minutes, emits time_updated, then checks if the day has ended

func advance_minute() -> void:
	game_minute += 1
	if game_minute >= 60:
		game_minute = 0
		game_hour  += 1

	emit_signal("time_updated", game_hour, game_minute)

	if game_hour >= END_HOUR:
		is_running = false
		emit_signal("day_ended")
