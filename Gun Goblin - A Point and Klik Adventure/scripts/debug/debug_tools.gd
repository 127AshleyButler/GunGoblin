extends Node

signal next_level
signal prev_level


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Handle debug inputs
	if Input.is_action_just_pressed("debug_reload"):
		print("[DEBUG] Reloaded scene!")
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed("debug_next_level"):
		print("[DEBUG] Next level!")
		next_level.emit()
	if Input.is_action_just_pressed("debug_prev_level"):
		print("[DEBUG] Prev level!")
		prev_level.emit()
