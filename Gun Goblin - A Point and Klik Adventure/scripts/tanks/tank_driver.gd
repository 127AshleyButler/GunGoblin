extends CharacterBody3D

signal killed(player_num)
signal loved(player_num)

@export var bullet_scene : PackedScene
@export var mine_scene : PackedScene
@export var heart_bullet_scene : PackedScene
@export_category("Tank Properties")
## How long the tank must wait before it is able to shoot again
@export_range(0, 1, 0.01, "or_greater", "or_less") var shooting_delay = 0.1
## How much time a shot needs to be charged until it upgrades to the next tier
@export_range(0, 3, 0.01, "or_greater", "or_less") var charge_tier_increment_time = 1
## The total number of active bullets this tank can have at once
@export_range(1, 99, 1, "or_greater", "or_less") var max_concurrent_bullets = 5
## The total number of active mines this tank can have at once
@export_range(1, 99, 1, "or_greater", "or_less") var max_concurrent_mines = 3
## The string representing which player controls this. "" For player 1, "2" for player 2, "3" for player 3, etc.
@export var player_num = ""

const DRIVING_SPEED = 10.0
const ROTATION_SPEED = 0.08
const JUMP_VELOCITY = 4.5

var can_shoot = false # Players can't shoot until the round has officially started
var current_shooting_delay = 0
var charge_shot_time = 0
var charge_tier = 0
var bullet_count = 0
var mine_count = 0
var received_love = false # Relates to getting hit with heart bullets

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	$model/AnimationPlayer.play("Idle")
	$AnimationPlayer.play("idle")
	for projectile in get_children():
		if projectile.is_in_group("Projectile"):
			remove_child(projectile)
			projectile.queue_free()
	can_shoot = false
	current_shooting_delay = 0
	charge_shot_time = 0
	charge_tier = 0
	bullet_count = 0
	mine_count = 0
	$model/PlayerLabel.text[3] = "V"
	received_love = false


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if can_shoot:
		# Handle charge shots
		if Input.is_action_pressed("shoot" + player_num) and current_shooting_delay <= 0:
			update_charge_shot(delta)
		# Handle charge mines
		if Input.is_action_pressed("lay_mine" + player_num) and current_shooting_delay <= 0:
			update_charge_shot(delta)
		# Handle charge hearts
		if Input.is_action_pressed("taunt" + player_num) and current_shooting_delay <= 0:
			update_charge_shot(delta)
		# Handle firing.
		if Input.is_action_just_released("shoot" + player_num):
			handle_shooting()
		# Handle mine laying
		if Input.is_action_just_released("lay_mine" + player_num):
			handle_mine_laying()
		# Handle firing heart bullets
		if Input.is_action_just_released("taunt" + player_num):
			handle_heart_shooting()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_axis("move_down" + player_num, "move_up" + player_num)
	var rotation_dir = Input.get_axis("move_right" + player_num, "move_left" + player_num)
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
	if (bullet_count >= max_concurrent_bullets):
		$Charging.emitting = false
		return
	if (current_shooting_delay > 0):
		return
	else:
		current_shooting_delay = shooting_delay
	bullet_count += 1
	var new_bullet = bullet_scene.instantiate()
	new_bullet.charge_tier = charge_tier
	new_bullet.position = $BulletSpawner.position
	new_bullet.parent_id = get_rid()
	add_child(new_bullet)
	$Fire.play()
	reset_charge()
	
	
func handle_mine_laying():
	if (mine_count >= max_concurrent_mines):
		$Charging.emitting = false
		return
	if (current_shooting_delay > 0):
		return
	else:
		current_shooting_delay = shooting_delay
	mine_count += 1
	var new_mine = mine_scene.instantiate()
	new_mine.charge_tier = charge_tier
	if charge_tier < 1: # Uncharged, lay mine directly behind tank.
		new_mine.position = $MineSpawner.position
	else: # Charged mine, shoot the mine outwards in an arc instead.
		new_mine.position = $BulletSpawner.position
		new_mine.airborne = true
		new_mine.launched = true
		$FireMine.play()
	add_child(new_mine)
	reset_charge()
	
	
func handle_heart_shooting():
	if (bullet_count >= max_concurrent_bullets):
		$Charging.emitting = false
		return
	if (current_shooting_delay > 0):
		return
	else:
		current_shooting_delay = shooting_delay
	bullet_count += 1
	var new_heart = heart_bullet_scene.instantiate()
	new_heart.charge_tier = charge_tier
	new_heart.position = $BulletSpawner.position
	new_heart.parent_id = get_rid()
	add_child(new_heart)
	$FireHeart.play()
	reset_charge()	
	
	
func hit():
	killed.emit(int(player_num))
	$AnimationPlayer.play("die")
	
	
func hit_with_love():
	if not received_love:
		received_love = true
		loved.emit(int(player_num))
		$model/PlayerLabel.text[3] = "♡"
	$AnimationPlayer.play("love")


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


func decrement_bullet_count():
	bullet_count -= 1


func decrement_mine_count():
	mine_count -= 1


func start_of_round(): # Called by the tank_game_master
	can_shoot = true


func update_label(player_num): # Called by the tank_game_master
	$model/PlayerLabel.text = "P" + player_num + "\nV"
