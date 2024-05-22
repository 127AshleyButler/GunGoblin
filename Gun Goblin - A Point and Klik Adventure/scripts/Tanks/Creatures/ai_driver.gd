extends CharacterBody3D

enum States {ALIVE, DEAD, INVISIBLE}

## How long from spawning in until this tank will start fighting
@export var activation_time := 3.0
## The state this tank starts in
@export var state = States.ALIVE
## How long this tank has to wait before it can search for a new target
@export var new_target_cooldown := 4.0

var _is_active = false
## The current tank driver this AI is hunting
var _current_target : TankDriver
## Whether or not this tank is waiting before it can find a new target
var _on_new_target_cooldown := false
## Whether or not this tank's muzzle is obscured by terrain (making shooting too dangerous)
var _is_safe_to_shoot := true


const DRIVING_SPEED = 10.0
const ROTATION_SPEED = 0.08

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

# Called when the node enters the scene tree for the first time.
func _ready():
	
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	
	# Make sure to not await during _ready.
	call_deferred("_actor_setup")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if not _is_active:
		return
	
	match state:
		States.ALIVE:
			_update_target()
			if _current_target:
				if _has_line_of_sight(_current_target):
					navigation_agent.set_target_position(_current_target.position)
					_rotate_towards(_current_target)
					_handle_shooting()
					$model/Label3D.text = "Firing"
				else: # Can't directly see the target, pathfind around a bit.
					$model/Label3D.text = "Tracking"
					if navigation_agent.is_navigation_finished():
						$model/Label3D.text = "Wandering"
						_handle_wandering()
					else:
						var current_agent_position: Vector3 = global_position
						var next_path_position: Vector3 = navigation_agent.get_next_path_position()

						velocity = current_agent_position.direction_to(next_path_position) * DRIVING_SPEED
						#_rotate_towards(next_path_position)
			else:
				$model/Label3D.text = "Wandering"
				_handle_wandering()
			move_and_slide()

func _actor_setup():
	
	$ActivationTimer.start(activation_time)

func hit():
	%AnimationPlayer.play("die")
	if state == States.ALIVE:
		state = States.DEAD


func _on_activation_timer_timeout():
	_is_active = true
	
	
func _rotate_towards(target: Node3D):
	# Based on: https://forum.godotengine.org/t/how-to-slowly-rotate-object-towards-another-object/18133/3
	var global_pos = global_transform.origin
	var target_pos = target.global_transform.origin
	var wtransform = global_transform.looking_at(Vector3(target_pos.x,global_pos.y,target_pos.z),Vector3(0,1,0)).rotated(Vector3(0,1,0), PI)
	var wrotation = Quaternion(global_transform.basis).slerp(Quaternion(wtransform.basis), ROTATION_SPEED)
	global_transform = Transform3D(Basis(wrotation), global_transform.origin)


func _handle_shooting():
	if not _is_safe_to_shoot:
		return
	# Try shooting
	if ($BulletEmitter.shoot()):
		%AnimationPlayer.play("shoot")
	

func _get_nearest_player() -> TankDriver:
	var players = get_tree().get_nodes_in_group("Player") as Array[TankDriver]
	var nearest_player
	var nearest_player_distance = INF
	for player in players:
		if player.state == TankDriver.States.ALIVE:
			var player_distance = position.distance_squared_to(player.position)
			if player_distance < nearest_player_distance:
				nearest_player_distance = player_distance
				nearest_player = player	
	return nearest_player


func _update_target():
	if _current_target: # Check if _current_target is still valid (alive)
		if _current_target.state != TankDriver.States.ALIVE:
			_current_target = null
	if not _current_target and not _on_new_target_cooldown:
		_current_target = _get_nearest_player()
		_on_new_target_cooldown = true
		$NewTargetTimer.start(new_target_cooldown)


func _on_new_target_timer_timeout():
	_on_new_target_cooldown = false


func _has_line_of_sight(target) -> bool:
	if not target:
		return false
	$VisionRaycast.position = position
	$VisionRaycast.look_at(target.position)
	var collision = $VisionRaycast.get_collider()
	if collision is TankDriver:
		return true
	return false

func _handle_wandering():
	if not _on_new_target_cooldown:
		$WanderRaycast.position = position
		$WanderRaycast.rotate_y(randf_range(0, 2*PI))
		var collision = $WanderRaycast.get_collider()
		if not collision:
			_on_new_target_cooldown = true
			$NewTargetTimer.start(new_target_cooldown)
			navigation_agent.set_target_position(_current_target.position)
	else:
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = 1 #randf_range(-1, 1)
		#var rotation_dir = move_toward(rotation.y, $WanderRaycast.rotation.y, ROTATION_SPEED)
		var direction
		#if rotation_dir:
			#rotate_y(rotation_dir * ROTATION_SPEED)
		_rotate_towards($WanderRaycast/End)
		var current_agent_position: Vector3 = global_position
		var next_path_position: Vector3 = navigation_agent.get_next_path_position()

		velocity = current_agent_position.direction_to(next_path_position) * DRIVING_SPEED
		#if input_dir:
			#direction = basis.z * input_dir
		#if direction:
			#velocity.x = direction.x * DRIVING_SPEED
			#velocity.z = direction.z * DRIVING_SPEED
		#else:
			#velocity.x = move_toward(velocity.x, 0, DRIVING_SPEED)
			#velocity.z = move_toward(velocity.z, 0, DRIVING_SPEED)


func _on_shooting_danger_zone_area_entered(area):
	_is_safe_to_shoot = false


func _on_shooting_danger_zone_area_exited(area):
	_is_safe_to_shoot = true


func _on_shooting_danger_zone_body_entered(body):
	_is_safe_to_shoot = false


func _on_shooting_danger_zone_body_exited(body):
	_is_safe_to_shoot = true
