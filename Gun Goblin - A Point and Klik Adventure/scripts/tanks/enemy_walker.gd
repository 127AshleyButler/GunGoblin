extends CharacterBody3D

enum States {ALIVE, DEAD}
enum Behaviours {IDLE, WANDERING, TRACKING, ATTACKING, ATTACK_COOLDOWN}

## How long from spawning in until this tank will start fighting
@export var activation_time := 3.0
## The state this tank starts in
@export var state = States.ALIVE
## How long this tank has to wait before it can search for a new target
@export var new_target_cooldown := 4.0
## The max distance allowed for line of sight checks
@export var line_of_sight_max_distance := 30
## How close this wants to get to its target before initiating an attack
@export var attack_range := 15
## How long this has to wait after an attack before it can perform other actions
@export var attack_cooldown := 2.0

## Whether or not this is currently active or still waiting for ActivationTimer to end
var _is_active := false
## The current tank driver this AI is hunting
var _current_target : TankDriver
## The current behaviour of this character
var _behaviour := Behaviours.WANDERING



const DRIVING_SPEED = 10.0
const ROTATION_SPEED = 0.08

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

# Called when the node enters the scene tree for the first time.
func _ready():
	if (activation_time > 0):
		$ActivationTimer.start(activation_time)
	else:
		_is_active = true
	
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	# Make sure to not await during _ready.
	call_deferred("_actor_setup")
	
	$model.play_animation("Idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$model/Label3D.text = Behaviours.keys()[_behaviour]
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	velocity.z = velocity.z * 0.9
	velocity.x = velocity.x * 0.9
	
	if _is_active:	
		match state:
			States.ALIVE:
				_update_target()
				match _behaviour:
					Behaviours.WANDERING:
						_handle_wandering()
					Behaviours.TRACKING:
						_handle_tracking()
					Behaviours.ATTACKING:
						_handle_attacking()
	move_and_slide()
				
			

func _actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame


func hit():
	%AnimationPlayer.play("die")
	if state == States.ALIVE:
		state = States.DEAD

	
	
func _rotate_towards(target: Vector3):
	# Based on: https://forum.godotengine.org/t/how-to-slowly-rotate-object-towards-another-object/18133/3
	var global_pos = global_transform.origin
	var target_pos = target
	var wtransform = global_transform.looking_at(Vector3(target_pos.x,global_pos.y,target_pos.z),Vector3(0,1,0)).rotated(Vector3(0,1,0), PI)
	var wrotation = Quaternion(global_transform.basis).slerp(Quaternion(wtransform.basis), ROTATION_SPEED)
	global_transform = Transform3D(Basis(wrotation), global_transform.origin)


func _get_nearest_player() -> TankDriver:
	var players = get_tree().get_nodes_in_group("Player") as Array[TankDriver]
	var nearest_player = null
	var nearest_player_distance = INF
	for player in players:
		if player.state == TankDriver.States.ALIVE and _has_line_of_sight(player):
			var player_distance = position.distance_squared_to(player.position)
			if player_distance < nearest_player_distance:
				nearest_player_distance = player_distance
				nearest_player = player	
	return nearest_player


func _update_target():
	if _current_target: # Check if _current_target is still valid (alive)
		if _current_target.state != TankDriver.States.ALIVE: # target is dead
			_current_target = null
			if _behaviour == Behaviours.ATTACKING or _behaviour == Behaviours.TRACKING:
				_behaviour = Behaviours.WANDERING
		elif _current_target.state == TankDriver.States.ALIVE: # Check if still has LOS to alive target
			if not _has_line_of_sight(_current_target): # No LOS to target, pathfind towards them
				if _behaviour == Behaviours.ATTACKING:
					_behaviour = Behaviours.TRACKING
			else: # has line of sight, check if close enough to be in attacking range
				if _behaviour == Behaviours.TRACKING \
						and (position.distance_to(_current_target.position) < attack_range):
					_behaviour = Behaviours.ATTACKING
	if not _current_target:
		_current_target = _get_nearest_player()
		if _current_target and _behaviour == Behaviours.WANDERING:
			_set_movement_target(_current_target.position)
			_behaviour = Behaviours.TRACKING
		#_on_new_target_cooldown = true
		#$NewTargetTimer.start(new_target_cooldown)



func _has_line_of_sight(target) -> bool:
	var space_state = get_world_3d().direct_space_state
	var origin = position
	var end = target.position
	if (origin.distance_to(end) > line_of_sight_max_distance):
		return false
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	
	var result = space_state.intersect_ray(query)
	if result and result.collider is TankDriver:
		return true
	return false

func _handle_wandering():
	pass

func _handle_tracking():
	if navigation_agent.is_navigation_finished():
		_set_movement_target(_current_target.position)

	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	_rotate_towards(next_path_position.rotated(Vector3(0, 1, 0), 2*PI))
	velocity = current_agent_position.direction_to(next_path_position) * DRIVING_SPEED
	$model.play_animation("Run")
	
func _handle_attacking():
	_rotate_towards(_current_target.position.rotated(Vector3(0, 1, 0), 2*PI))
	#velocity = position.direction_to(_current_target.position) * DRIVING_SPEED
	if ($BulletEmitter.shoot()):
		%AnimationPlayer.play("shoot")
	
func _attack_end():
	if attack_cooldown > 0: # Start attack cooldown timer (unless it's 0)
		$AttackCooldown.start(attack_cooldown)
		_behaviour = Behaviours.ATTACK_COOLDOWN

func _set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)


func _on_activation_timer_timeout():
	_is_active = true


func _on_attack_cooldown_timeout():
	_behaviour = Behaviours.TRACKING
