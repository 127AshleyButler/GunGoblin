extends CharacterBody3D

@export var bullet_scene : PackedScene
@export var mine_scene : PackedScene
@export_category("Tank Properties")
## How long the tank must wait before it is able to shoot again
@export_range(0, 1, 0.01, "or_greater", "or_less") var shooting_delay = 0.1
## How much time a shot needs to be charged until it upgrades to the next tier
@export_range(0, 3, 0.01, "or_greater", "or_less") var charge_tier_increment_time = 1
## The string representing which player controls this. "" For player 1, "2" for player 2, "3" for player 3, etc.
@export var player_string = ""

const DRIVING_SPEED = 10.0
const ROTATION_SPEED = 0.08
const JUMP_VELOCITY = 4.5

var current_shooting_delay = 0
var current_frozen_time = 0
var charge_shot_time = 0
var charge_tier = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	$model/AnimationPlayer.play("Idle")
	$AnimationPlayer.play("idle")
	print(Input.get_connected_joypads())

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle charge shots
	if Input.is_action_pressed("shoot" + player_string) and current_shooting_delay <= 0:
		update_charge_shot(delta)
		
	# Handle firing.
	if Input.is_action_just_released("shoot" + player_string):
		handle_shooting()
		
	# Handle mine laying
	if Input.is_action_just_pressed("lay_mine" + player_string):
		handle_mine_laying()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_axis("move_down" + player_string, "move_up" + player_string)
	
	var rotation_dir = Input.get_axis("move_right" + player_string, "move_left" + player_string)
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
	
	update_timers(delta)

func update_timers(delta):
	current_shooting_delay -= delta

func handle_shooting():
	if (current_shooting_delay > 0):
		return
	else:
		current_shooting_delay = shooting_delay
	var new_bullet = bullet_scene.instantiate()
	new_bullet.charge_tier = charge_tier
	new_bullet.position = $BulletSpawner.position
	add_child(new_bullet)
	$Fire.play()
	reset_charge()
	
func handle_mine_laying():
	if (current_shooting_delay > 0):
		return
	else:
		current_shooting_delay = shooting_delay
	var new_mine = mine_scene.instantiate()
	new_mine.charge_tier = charge_tier
	if charge_tier < 1: # Uncharged, lay mine directly behind tank.
		new_mine.position = $MineSpawner.position
	else: # Charged mine, shoot the mine outwards in an arc instead.
		new_mine.position = $BulletSpawner.position
		new_mine.is_shot = true
	add_child(new_mine)
	reset_charge()
	
func hit():
	$AnimationPlayer.play("die")

func reset_charge():
	charge_shot_time = 0
	charge_tier = 0
	$Charging.emitting = false

func update_charge_shot(delta):
	charge_shot_time += delta
	$Charging.emitting = true
	if charge_shot_time >= charge_tier_increment_time:
		charge_shot_time -= charge_tier_increment_time
		$ChargeTierIncreased.pitch_scale = 1 + (0.1 * charge_tier)
		$ChargeTierIncreased.play()
		charge_tier += 1
		$ChargeTierIncreasedParticles.emitting = true
