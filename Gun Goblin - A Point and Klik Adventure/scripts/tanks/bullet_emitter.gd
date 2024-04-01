extends Node3D

@export var bullet_scene: PackedScene


## The total number of bullets that can be active at once, leave at -1 for infinite.
@export_range(-1, 99, 1, "or_greater", "or_less") var max_concurrent_bullets = -1

## The time this emitter must wait after successfully firing before it can fire again
@export var shooting_delay := 0.0

## Whether or not this emitter is currently enabled (e.g., disabled before the current round has started)
@export var enabled := true

var _active_bullets = 0

var _on_delay = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Emits a bullet, returns true if successful, false otherwise (e.g., because there were too many bullets)
func shoot() -> bool:
	# Return early if bullet can't be fired
	if not bullet_scene or not enabled:
		return false
	if max_concurrent_bullets != -1 and _active_bullets >= max_concurrent_bullets:
		return false
	if _on_delay:
		return false
		
	# Bullet can be successfully shot
	var _new_bullet = bullet_scene.instantiate()
	_active_bullets += 1
	add_child(_new_bullet)
	
	$ShotDelayTimer.start(shooting_delay)
	_on_delay = true
	return true


func _on_shot_delay_timer_timeout():
	_on_delay = false
