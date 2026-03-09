extends CanvasLayer

@onready var rect: ColorRect = $FadeRect
var _tween: Tween

func _ready() -> void:
	# Start invisible
	rect.modulate.a = 0.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func go_to(scene_path: String, duration := 0.05) -> void:
	# Kill any previous fade if user spam-clicks
	if _tween and _tween.is_valid():
		_tween.kill()

	# Block clicks during transition
	rect.mouse_filter = Control.MOUSE_FILTER_STOP

	_tween = create_tween()
	_tween.tween_property(rect, "modulate:a", 1.0, duration)
	_tween.tween_callback(Callable(self, "_change_scene").bind(scene_path))
	_tween.tween_property(rect, "modulate:a", 0.0, duration)
	_tween.tween_callback(Callable(self, "_done"))

func _change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

func _done() -> void:
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
