#class_name MeleeComponent
extends Node3D

signal prepped_attack()
signal attack_started()
signal attack_duration_ended()
signal attack_cooldown_ended()

enum States {IDLE, ATTACK_START, ATTACKING, ATTACK_COOLDOWN}

## The startup time before this AI releases its attack
@export var attack_startup :float = 0.5
## How long this attack lasts before it goes into cooldown
@export var attack_duration : float = 0.7
## How long this has to wait after an attack before it can perform other actions
@export var attack_cooldown : float = 2.0
## The speed at which this character moves while attacking
@export var attack_speed : float = 20.0
## Whether or not this attack component is currently active
@export var is_active : bool = true


var _state : States = States.IDLE


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_active:	
		match _state:
			States.ATTACK_START:
				pass
			States.ATTACKING:
				_handle_attacking()


func try_attacking() -> bool:
	if _state == States.IDLE:
		_start_attack()
		return true
	return false
	

func _start_attack():
	prepped_attack.emit()
	_state = States.ATTACK_START
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


func _on_attack_duration_timeout():
	attack_duration_ended.emit()
	$AttackHitbox.monitoring = false
	if attack_cooldown > 0: # Start attack cooldown timer (unless it's 0)
		$AttackCooldown.start(attack_cooldown)
		_state = States.ATTACK_COOLDOWN
	else: # No cooldown, immediately end attack
		_end_attack()
		

func _on_attack_cooldown_timeout():
	_end_attack()
	
	
func _end_attack():
	attack_cooldown_ended.emit()
	_state = States.IDLE


func _on_attack_hitbox_body_entered(body):
	if body.has_method("hit"):
		body.hit()
