#class_name MeleeComponent
extends Node3D

signal prepped_attack()
signal attack_started()
signal attack_cooldown_started()
signal attack_ended()

enum States {IDLE, ATTACK_START, ATTACKING, ATTACK_COOLDOWN}

## The startup time before this AI releases its attack
@export var attack_startup :float = 0.5
## How long this attack lasts before it goes into cooldown
@export var attack_duration : float = 0.7
## How long this has to wait after an attack before it can perform other actions
@export var attack_cooldown : float = 2.0
## The speed at which this character moves while attacking
@export var attack_speed : float = 20.0
@export var rotation_speed : float = 0.08
## Whether or not this attack component is currently active
@export var is_active : bool = true


var _state : States = States.IDLE
## Direction this AI is attacking at if it is in the attacking state
var _attack_direction : Vector3
## The current tank driver this AI is hunting
var _current_target : TankDriver


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_active:	
		match _state:
			States.ATTACK_START:
				_rotate_towards((position + _attack_direction).rotated(Vector3(0, 1, 0), 2*PI))
			States.ATTACKING:
				_handle_attacking()


func try_attacking() -> bool:
	if _state == States.IDLE:
		_start_attack()
		return true
	return false
	
func _rotate_towards(target: Vector3):
	# Based on: https://forum.godotengine.org/t/how-to-slowly-rotate-object-towards-another-object/18133/3
	var global_pos = global_transform.origin
	var target_pos = target
	var wtransform = global_transform.looking_at(Vector3(target_pos.x,global_pos.y,target_pos.z),Vector3(0,1,0)).rotated(Vector3(0,1,0), PI)
	var wrotation = Quaternion(global_transform.basis).slerp(Quaternion(wtransform.basis), rotation_speed)
	#var _this_scale = scale
	global_transform = Transform3D(Basis(wrotation), global_transform.origin)
	#scale = _this_scale


func _start_attack():
	prepped_attack.emit()
	_state = States.ATTACK_START
	_attack_direction = position.direction_to(_current_target.position)
	if (attack_startup > 0):
		$AttackStartup.start(attack_startup)
	else:
		_initiate_attack()
	

func _on_attack_startup_timeout():
	_initiate_attack()
		

func _initiate_attack():
	attack_started.emit()
	$AttackHitbox.monitoring = true
	_state = States.ATTACKING
	if (attack_duration > 0):
		$AttackDuration.start(attack_duration)
	else: # No attack duration, so just run _handle_attacking once
		_handle_attacking()

	
func _handle_attacking():
	pass
	#velocity = _attack_direction * attack_speed
	#if (position.distance_to(_attack_direction) < min_attack_distance):
		## End the attack duration early, as the target was reached already
		#$AttackDuration.stop()
		#_on_attack_duration_timeout()


func _on_attack_duration_timeout():
	attack_cooldown_started.emit()
	$AttackHitbox.monitoring = false
	if attack_cooldown > 0: # Start attack cooldown timer (unless it's 0)
		$AttackCooldown.start(attack_cooldown)
		_state = States.ATTACK_COOLDOWN
	else: # No cooldown, immediately end attack
		_end_attack()
		

func _on_attack_cooldown_timeout():
	_end_attack()
	
	
func _end_attack():
	attack_ended.emit()
	_state = States.IDLE


func _on_attack_hitbox_body_entered(body):
	if body.has_method("hit"):
		body.hit()
