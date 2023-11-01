extends CharacterBody3D


const SPEED = 12.0
const JUMP_VELOCITY = 5.5


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var _spring_arm: SpringArm3D = $SpringArm3D 
@onready var _pivot: Node3D = $pivot
#@onready var _eye: BoneAttachment3D = $pivot/Skeleton3D/puppet/"con.eyes"
@export var _eye: BoneAttachment3D

func _process(delta):
	pass


# this is all code i copied over from the other mover thingie. same for the springarm3d :I
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	direction = direction.rotated(Vector3.UP, _spring_arm.rotation.y).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED	
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if velocity.length() > 0.2:
		var look_direction = Vector2(velocity.z, velocity.x)
		_pivot.rotation.y = look_direction.angle()		
	_spring_arm.position = position #Moves spring arm w/ us
	move_and_slide()
