extends Node2D

var rigidBodies

# Called when the node enters the scene tree for the first time.
func _ready():
	rigidBodies = $"SoftBody2D".find_children("Bone-?", "RigidBody2D")
	for RB in rigidBodies:
		RB.add_to_group("rigid_body")
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#$"SoftBody2D/Bone-0".add_constant_force()
	
	$Music.pitch_scale = clampf($"SoftBody2D/Bone-0".linear_velocity.length() / 300, 0.2, 1.2)
	
	
	for RB in rigidBodies:
		RB.linear_velocity = RB.global_position.direction_to(get_global_mouse_position()) * RB.global_position.distance_to(get_global_mouse_position())

	


func _on_music_finished():
	$Music.play()



	
