extends CharacterBody3D

@export var target_location = Node3D
@export var backwards_speed = 18.0
@export var backwards_speed_decay = 0.02
@export var auto_start = false
## Whether or not this spike top is currently active & able to damage players
var is_active = false

const SPEED = 5.0 / 100
var sliding_backwards = false
var kickback_direction
var current_backwards_speed_multiplier = 1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	if (auto_start):
		$AnimationPlayer.play("activation")
	else:
		$AnimationPlayer.play("inactive")


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle movement
	if sliding_backwards and is_active:
		handle_slide_backwards()
	elif is_active:
		var input_dir = target_location.global_position - position
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.z)).normalized()
		#direction.rotated(Vector3(1, 0, 0),  PI/2)
		if direction:
			$Model/PupilCenter.look_at(position - direction)
			velocity.x += direction.x * SPEED + randf_range(-0.05, 0.05)
			velocity.z += direction.z * SPEED + randf_range(-0.05, 0.05)
		else:
			velocity.x += move_toward(velocity.x, 0, SPEED)
			velocity.z += move_toward(velocity.z, 0, SPEED)
	move_and_slide()
	#var collision = move_and_collide(velocity * delta)
	#if collision:
		#velocity = velocity.slide(collision.get_normal())


func activate():
	$AnimationPlayer.play("activation")


## Used to make the spiketop bounce backwards after colliding with something.
## Also called by tank_mine when the spike top gets with a mine explosion.
func _on_hurtbox_body_entered(body, force_multiplier = 1):
	if not is_active:
		return
	kickback_direction = (position - body.position).normalized()
	current_backwards_speed_multiplier = 1 * force_multiplier
	sliding_backwards = true
	$AnimationPlayer.play("slide_backwards")
	if body.has_method("hit"):
		body.hit()
		
		
func _on_hurtbox_area_entered(area):
	if not is_active:
		return
	if area.has_method("hit"):
		area.hit()


func handle_slide_backwards():
	velocity.x = kickback_direction.x * backwards_speed * current_backwards_speed_multiplier
	velocity.z = kickback_direction.z * backwards_speed * current_backwards_speed_multiplier
	current_backwards_speed_multiplier -= backwards_speed_decay
	if (current_backwards_speed_multiplier <= 0):
		sliding_backwards = false
		$AnimationPlayer.play("spinning")




