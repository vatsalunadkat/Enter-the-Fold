extends Node2D

#references to UI nodes
@onready var label        : Label       = $Label
@onready var progress_bar : ProgressBar = $ProgressBar
@onready var status_label : Label       = $StatusLabel

#daytimer instance, no need to place it in the scene
var day_timer = DayTimer.new()


func _ready() -> void:
	# configure range of progress bar at runtime
	progress_bar.min_value       = 0.0
	progress_bar.max_value       = 100.0
	progress_bar.value           = 0.0
	progress_bar.show_percentage = true

#puts daytimer in the scene tree so _process() runs and the clock can tick
	add_child(day_timer)
	day_timer.time_updated.connect(_on_time_updated)
	day_timer.day_ended.connect(_on_day_ended)
	#kick off the clock — resets to 8:00 AM 
	day_timer.start_day()

	status_label.text = "Day in progress..."

#returns bar range *100 and ensure the bar increases slowly
func _process(_delta: float) -> void:
	progress_bar.value = day_timer.get_progress() * 100.0

#how time is formatted
func _on_time_updated(hour: int, _minute: int) -> void:
	label.text = day_timer.get_time_string()

	# turn label orange in the afternoon
	if hour >= 12:
		label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1))
	else:
		label.remove_theme_color_override("font_color")

	# log every hour turn to the console
	if _minute == 0:
		print("[Test] Hour: %s" % day_timer.get_time_string())

#UI elements updated to reflect that the day is over
func _on_day_ended() -> void:
	label.text = "DAY OVER!"
	status_label.text = "Day over, no new customers!"
	status_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	progress_bar.value = 100.0
	print("[Test] day_ended signal received.")


# press Space to test stop()/resume()
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			if day_timer.is_running:
				day_timer.stop()
				status_label.text = "Paused (space to resume)"
			else:
				day_timer.resume()
				status_label.text = "Day in progress..."
