extends Node3D



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Reload the current scene by pressing [F5]. Note: some things like custom tile data behave differently when reloading this way, but it can be handy to quickly test small changes to the project multiple times.
	if Input.is_action_just_pressed("debug_reload"):
		print("[DEBUG] Reloaded scene!")
		get_tree().reload_current_scene()
