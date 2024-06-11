class_name MinesMcgee
extends CharacterBody3D

signal die

enum States {ALIVE, DEAD}
enum Behaviours {IDLE, WANDERING, TRACKING, ATTACK_START, ATTACKING, ATTACK_COOLDOWN}


@export_category("Basic Stats")
## How long from spawning in until this tank will start fighting
@export var activation_time : float = 3.0
## The state this tank starts in
@export var state : States = States.ALIVE
## The max distance allowed for line of sight checks
@export var line_of_sight_max_distance : float = 45
## How close this wants to get to its target before initiating an attack
@export var attack_range : float = 15
## The startup time before this AI releases its attack
@export var attack_startup :float = 0.5
## How long this attack lasts before it goes into cooldown
@export var attack_duration : float = 0.7
## How long this has to wait after an attack before it can perform other actions
@export var attack_cooldown : float = 2.0

@export_category("MinesMcgee")
## How many mines MinesMcgee starts with
@export var mine_count : int = 0
## Max number of mines MinesMcgee can hold
@export var max_mines : int = 5


## Whether or not this is currently active or still waiting for ActivationTimer to end
var _is_active := false
## The current tank driver this AI is hunting
var _current_target : TankDriver
## The current behaviour of this character
var _behaviour := Behaviours.WANDERING
## Direction this AI is attacking at if it is in the attacking state
var _attack_direction : Vector3

var _current_mine_target : Mine


const DRIVING_SPEED = 10.0
const ATTACK_SPEED = 5.0
const ROTATION_SPEED = 0.08
const WANDER_SPEED = 5.0

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
					Behaviours.ATTACK_START:
						_rotate_towards((position + _attack_direction).rotated(Vector3(0, 1, 0), 2*PI))
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
		die.emit()

	
	
func _rotate_towards(target: Vector3):
	# Based on: https://forum.godotengine.org/t/how-to-slowly-rotate-object-towards-another-object/18133/3
	var global_pos = global_transform.origin
	var target_pos = target
	var wtransform = global_transform.looking_at(Vector3(target_pos.x,global_pos.y,target_pos.z),Vector3(0,1,0)).rotated(Vector3(0,1,0), PI)
	var wrotation = Quaternion(global_transform.basis).slerp(Quaternion(wtransform.basis), ROTATION_SPEED)
	#var _this_scale = scale
	global_transform = Transform3D(Basis(wrotation), global_transform.origin)
	#scale = _this_scale


func _get_nearest_player() -> TankDriver:
	var players = get_tree().get_nodes_in_group("Player") as Array[TankDriver]
	var nearest_player = null
	var nearest_player_distance = INF
	for player in players:
		if player.state == TankDriver.States.ALIVE and _has_line_of_sight(player, TankDriver):
			var player_distance = position.distance_squared_to(player.position)
			if player_distance < nearest_player_distance:
				nearest_player_distance = player_distance
				nearest_player = player	
	return nearest_player
	
	
func _get_nearest_mine() -> Mine:
	var Mines = get_tree().get_nodes_in_group("Mine") as Array[Mine]
	var nearest_mine = null
	var nearest_mine_distance = INF
	for mine in Mines:
		if mine.state == Mine.States.PRIMED and _has_line_of_sight(mine, Mine):
			var mine_distance = position.distance_squared_to(mine.position)
			if mine_distance < nearest_mine_distance:
				nearest_mine_distance = mine_distance
				nearest_mine = mine	
	return nearest_mine


func _update_target():
	if mine_count < max_mines:
		if is_instance_valid(_current_mine_target):
			if _current_mine_target.state != Mine.States.PRIMED: # target is dead
				_current_mine_target = null
				if _behaviour == Behaviours.TRACKING:
					_behaviour = Behaviours.WANDERING
			elif _current_mine_target.state == Mine.States.PRIMED: # Check if still has LOS to alive target
				if _has_line_of_sight(_current_mine_target, Mine): # has line of sight, check if close enough to be in attacking range
					if _behaviour == Behaviours.TRACKING \
							and (position.distance_to(_current_mine_target.position) < attack_range):
						_mine_pickup()
		elif not is_instance_valid(_current_mine_target):
			_current_mine_target = _get_nearest_mine()
			if _current_mine_target and _behaviour == Behaviours.WANDERING:
				_set_movement_target(_current_mine_target.position)
				_behaviour = Behaviours.TRACKING
			elif not _current_mine_target and _behaviour == Behaviours.TRACKING:
				_behaviour = Behaviours.WANDERING
	else: # Already has max mines, search for players
		if _current_target: # Check if _current_target is still valid (alive)
			if _current_target.state != TankDriver.States.ALIVE: # target is dead
				_current_target = null
				if _behaviour == Behaviours.TRACKING:
					_behaviour = Behaviours.WANDERING
			elif _current_target.state == TankDriver.States.ALIVE: # Check if still has LOS to alive target
				if _has_line_of_sight(_current_target, TankDriver): # has line of sight, check if close enough to be in attacking range
					if _behaviour == Behaviours.TRACKING \
							and (position.distance_to(_current_target.position) < attack_range):
						_fall_down_attack()
		elif not _current_target:
			_current_target = _get_nearest_player()
			if _current_target and _behaviour == Behaviours.WANDERING:
				_set_movement_target(_current_target.position)
				_behaviour = Behaviours.TRACKING
			elif not _current_target and _behaviour == Behaviours.TRACKING:
				_behaviour = Behaviours.WANDERING


func _mine_pickup():
	$MineMeleeComponent.try_attacking()
	%AnimationPlayer.play("Pickup")
	

func _fall_down_attack():
	%AnimationPlayer.play("FallDownFunny")


func _has_line_of_sight(target, typeToCheck) -> bool:
	var space_state = get_world_3d().direct_space_state
	var origin = position
	var end = target.position
	if (origin.distance_to(end) > line_of_sight_max_distance):
		return false
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	
	var result = space_state.intersect_ray(query)
	if result and is_instance_of(result.collider, typeToCheck):
		return true
	return false

func _handle_wandering():
	%AnimationPlayer.play("Run")
	velocity = Vector3(0, 0, 1).rotated(Vector3(0, 1, 0), rotation.y) * WANDER_SPEED
	var collision = move_and_collide(velocity, true)
	if collision:
		rotate_y(PI / 2)

func _handle_tracking():
	if navigation_agent.is_navigation_finished():
		if (_current_target):
			_set_movement_target(_current_target.position)

	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	_rotate_towards(next_path_position.rotated(Vector3(0, 1, 0), 2*PI))
	velocity = current_agent_position.direction_to(next_path_position) * DRIVING_SPEED
	%AnimationPlayer.play("Run")
	
	
func _start_mine_grab_attack():
	%AnimationPlayer.play("Gnash")
	_behaviour = Behaviours.ATTACK_START
	_attack_direction = position.direction_to(_current_mine_target.position)

		

func _initiate_attack():
	%AnimationPlayer.play("Leap")
	_behaviour = Behaviours.ATTACKING

	
func _handle_attacking():
	velocity = _attack_direction * ATTACK_SPEED


func _on_attack_duration_timeout():
	%AnimationPlayer.play("Splat")
	_behaviour = Behaviours.ATTACK_COOLDOWN
	
	
func _end_attack():
	_behaviour = Behaviours.TRACKING


func _set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)


func _on_activation_timer_timeout():
	_is_active = true


func _on_attack_hitbox_body_entered(body):
	if body.has_method("hit"):
		body.hit()


func _on_melee_component_hit(body):
	if body.is_in_group("Mine"):
		body.disappear()
		mine_count = min(max_mines, mine_count + 1)
