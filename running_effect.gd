extends Sprite2D

var state = "idle"
var _tween: Tween

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func start_iron() -> void:
	state = "running"
	_tween = create_tween().set_loops()
	_tween.tween_property(self, "position:x", 10.0, 0.5)
	_tween.tween_property(self, "position:x", -5.0, 0.5)

func stop_iron() -> void:
	state = "idle"
	if _tween:
		_tween.kill()
	position.x = 0.0
