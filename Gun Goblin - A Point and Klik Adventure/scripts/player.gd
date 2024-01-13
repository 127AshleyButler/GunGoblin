extends "character.gd"

@export var player_num = 1

var facing = -1 # The direction the player is facing
var direction = 0
var canShoot = true
var canDive = true

const DIVE_SPEED = 50.0
const WALL_SLIDE_GRAVITY_MODIFIER = 0.9
const HORIZONTAL_WALL_JUMP_SPEED = 50.0
const MAX_FALLING_SPEED = -50.0
const HOLDING_DOWN_FALLING_MULTIPLIER = 2.0

func _ready():
	health = 100
	super._ready()
	$AnimatedSprite3D.play("idle_l")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
		air_time += delta
	else:
		air_time = 0
		canShoot = true
		canDive = true

	# Handle Wall Sliding
	if is_touching_wall() and not is_on_floor():
		# Wall Slide
		if velocity.y < 0:
			velocity.y = gravity * -WALL_SLIDE_GRAVITY_MODIFIER * delta

	# Lessen the gravity if jump is held
	if Input.is_action_pressed("jump"):
		gravity = world_gravity * LOW_GRAVITY_MODIFIER
	else:
		gravity = world_gravity * HIGH_GRAVITY_MODIFIER

	# Handle Jump.
	if Input.is_action_just_pressed("jump"):
		handle_jump()
	
	# Handle Shoot.
	if Input.is_action_just_pressed("shoot"):
		handle_shoot()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_axis("move_left", "move_right")
	if direction:
		facing = direction
		velocity.x = direction * SPEED
		#velocity.x = max_speed(direction * SPEED, velocity.x)
	else:
		#$AnimatedSprite2D.stop()
		#velocity.x = max_speed(move_toward(velocity.x, 0, SPEED), velocity.x)
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	# Handle Dive.
	if Input.is_action_just_pressed("dive"):
		handle_dive()
	if (Input.is_action_pressed("move_down")):
		velocity.y = max(velocity.y, MAX_FALLING_SPEED * HOLDING_DOWN_FALLING_MULTIPLIER)
	else:
		velocity.y = max(velocity.y, MAX_FALLING_SPEED)
	move_and_slide()
	
	update_animation_parameters()
	
func update_animation_parameters():
	# For animations that have left/right versions, this is how to let them know which version to play.
	$AnimationTree["parameters/idle/blend_position"] = facing
	$AnimationTree["parameters/run/blend_position"] = facing
	$AnimationTree["parameters/sit/blend_position"] = facing
	$AnimationTree["parameters/airborne/blend_position"] = Vector2(facing, velocity.y)
	$AnimationTree["parameters/Wall Cling/blend_position"] = Vector2(facing, velocity.y)
	
	# Update conditions of other animations
	$AnimationTree["parameters/conditions/holding_down"] = Input.is_action_pressed("move_down")
	$AnimationTree["parameters/conditions/not_holding_down"] = !Input.is_action_pressed("move_down")
	$AnimationTree["parameters/conditions/idle"] = (Input.get_axis("move_left", "move_right") == 0) and (is_on_floor())
	
func handle_jump():
	# Handle Jump.
	if is_on_floor() or air_time < JUMP_GRACE_PERIOD:
		velocity.y = JUMP_VELOCITY
		air_time = JUMP_GRACE_PERIOD
		$SFX/jump.play()
		# Handle Wall Jumps
	if is_touching_wall() and not is_on_floor():
		# Wall Jump
		velocity.x = HORIZONTAL_WALL_JUMP_SPEED * -facing
		velocity.y = JUMP_VELOCITY
		air_time = JUMP_GRACE_PERIOD
		$SFX/jump.play()
		
func handle_dive():
	if (not canDive):
		return
	canDive = false
	velocity.x = facing * DIVE_SPEED

func handle_shoot():
	if canShoot:
		canShoot = false
		velocity.y = WALL_SLIDE_VELOCITY

func max_speed(speed1, speed2):
	# Input: 2 speeds represented as signed floats.
	# Output: the greater of the two speeds, disregarding direction.
	if (abs(speed1) > abs(speed2)):
		return speed1
	else:
		return speed2
	
func is_touching_wall():
	if $WallClingRight.is_colliding() and facing == 1 and not Input.is_action_pressed("move_down"):
		return 1
	if $WallClingLeft.is_colliding() and facing == -1 and not Input.is_action_pressed("move_down"):
		return -1
	return false

