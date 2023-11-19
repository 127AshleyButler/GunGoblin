extends "character.gd"

@export var player_num = 1

var facing = -1 # The direction the player is facing
var current_animation = "idle_l"
var canShoot = true

func _ready():
	health = 100
	super._ready()
	$AnimatedSprite3D.play("idle_l")

func _physics_process(delta):
	# Handle debug inputs
	if Input.is_action_just_pressed("debug_reload"):
		print("[DEBUG] Reloaded scene!")
		get_tree().reload_current_scene()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		air_time += delta
	else:
		air_time = 0
		canShoot = true

	# Handle Wall Sliding
	if is_touching_wall():
		# Wall Slide
		if velocity.y > 0:
			velocity.y = WALL_SLIDE_VELOCITY

	# Lessen the gravity if jump is held
	if Input.is_action_pressed("jump"):
		gravity = world_gravity * LOW_GRAVITY_MODIFIER
	else:
		gravity = world_gravity * HIGH_GRAVITY_MODIFIER

	# Handle Jump.
	if Input.is_action_just_pressed("jump"):
		handle_jump()
	
	if Input.is_action_just_pressed("shoot"):
		handle_shoot()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		facing = direction
		#$AnimatedSprite2D.play("default")
#		if (direction == -1):
#			$AnimationPlayer.play("run_l")
#		else:
#			$AnimationPlayer.play("run_r")
		velocity.x = direction * SPEED
	else:
		#$AnimatedSprite2D.stop()
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	update_animation_parameters()
	
func update_animation_parameters():
	$AnimationTree["parameters/idle/blend_position"] = facing
	$AnimationTree["parameters/run/blend_position"] = facing
	$AnimationTree["parameters/rise/blend_position"] = facing
	$AnimationTree["parameters/fall/blend_position"] = facing
	$AnimationTree["parameters/sit/blend_position"] = facing

	$AnimationTree["parameters/conditions/idle"] = (velocity == Vector3.ZERO)
	$AnimationTree["parameters/conditions/holding_down"] = Input.is_action_pressed("move_down")
	$AnimationTree["parameters/conditions/not_holding_down"] = !Input.is_action_pressed("move_down")

func handle_shoot():
	if canShoot:
		canShoot = false
		velocity.y += WALL_SLIDE_VELOCITY
	
