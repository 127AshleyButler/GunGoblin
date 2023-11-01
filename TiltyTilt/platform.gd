extends AnimatableBody3D


@export var rotspeed = 0.05
var direction = Vector3.UP
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var rot_z = 0
	var rot_x = 0
	if Input.is_action_pressed("ui_left"):
		rot_z -= rotspeed
	if Input.is_action_pressed("ui_right"):
		rot_z += rotspeed
	if Input.is_action_pressed("ui_up"):
		rot_x -= rotspeed
	if Input.is_action_pressed("ui_down"):
		rot_x += rotspeed
	#rotate_x(rot_x)
	#rotate_z(rot_z)
	transform = transform.rotated(Vector3.FORWARD,rot_z).rotated(Vector3.RIGHT,rot_x)
	##transform = transform.
	
		
