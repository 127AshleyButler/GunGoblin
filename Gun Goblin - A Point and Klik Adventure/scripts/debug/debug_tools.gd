extends Node


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Handle debug inputs
	if Input.is_action_just_pressed("debug_reload"):
		print("[DEBUG] Reloaded scene!")
		get_tree().reload_current_scene()