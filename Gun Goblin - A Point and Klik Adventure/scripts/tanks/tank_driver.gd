extends CharacterBody3D

@export var bullet_scene : PackedScene

const DRIVING_SPEED = 10.0
const ROTATION_SPEED = 0.08
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	$model/AnimationPlayer.play("Idle")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle firing.
	if Input.is_action_just_pressed("shoot"):
		handle_shooting()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_axis("move_down", "move_up")
	
	var rotation_dir = Input.get_axis("move_right", "move_left")
	var direction
	if rotation_dir:
		rotate_y(rotation_dir * ROTATION_SPEED)
	if input_dir:
		direction = basis.z * input_dir
	if direction:
		velocity.x = direction.x * DRIVING_SPEED
		velocity.z = direction.z * DRIVING_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, DRIVING_SPEED)
		velocity.z = move_toward(velocity.z, 0, DRIVING_SPEED)

	move_and_slide()


func handle_base_rotation(target_direction):
	#var baseBone = $model/Armature/Skeleton3D.get_bone_pose(1)
	#baseBone.look_at(target_direction)
	#$model/Armature/Skeleton3D.set_bone_pose(1, baseBone)
	pass

func handle_shooting():
	var new_bullet = bullet_scene.instantiate()
	new_bullet.position = $BulletSpawner.position
	add_child(new_bullet)
	$Fire.play()
	
func hit():
	print("by god i've been hit")
