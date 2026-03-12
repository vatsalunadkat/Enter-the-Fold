extends Node

var is_transitioning := false

func go_to(scene_path: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true

	# Block input to avoid rapid-click problems
	var root := get_tree().root
	root.set_process_input(false)
	root.set_process_unhandled_input(false)

	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("SceneRouter failed to load: %s (err=%s)" % [scene_path, str(err)])

	call_deferred("_finish_transition")

func _finish_transition() -> void:
	var root := get_tree().root
	root.set_process_input(true)
	root.set_process_unhandled_input(true)
	is_transitioning = false
