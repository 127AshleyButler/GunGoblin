extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func _physics_process(delta):
	$AnimatableBody3D.rotate_y(15 * delta)

