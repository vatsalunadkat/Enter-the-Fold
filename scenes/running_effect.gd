extends Sprite2D

var _tween: Tween

func _ready() -> void:
	pass

func start_register() -> void:
	_tween = create_tween().set_loops()
	_tween.tween_property(self, "modulate", Color(1.5, 1.5, 0.5, 1.0), 0.2)
	_tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func stop_register() -> void:
	if _tween:
		_tween.kill()
	modulate = Color.WHITE
