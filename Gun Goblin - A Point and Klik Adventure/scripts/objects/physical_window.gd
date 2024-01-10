extends AnimatedSprite3D

@export var physics_component : RigidBody3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position = physics_component.global_position
	pass
	#var diff = global_position - physics_component.global_position
	#global_position += diff
