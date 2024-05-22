extends Node3D

@export var fire_projectile : PackedScene
@export var is_active = false

var max_rotation_speed = 1.5
#var max_rotation_speed = 300
var current_rotation_speed = 0
var time = 0.0
var fire_timer = 0.25
var current_fire_timer = fire_timer

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer2.play("initial")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not is_active:
		return
	time += delta * 0.005
	current_rotation_speed = clampf( lerpf(0, max_rotation_speed, time), 0, max_rotation_speed)
	$garf.rotate_y(current_rotation_speed * delta)
	$Pillar.rotate_y(current_rotation_speed * delta)
	
	current_fire_timer -= delta
	if (current_fire_timer <= 0):
		current_fire_timer += fire_timer
		shoot_fire()


func shoot_fire():
	var new_fire = fire_projectile.instantiate()
	new_fire.position = $Pillar/FireSpawn.global_position
	new_fire.rotation = $garf.rotation
	add_child(new_fire)


func _on_activation_timer_timeout():
	$Pillar/StoneScraping.play()
	$AnimationPlayer2.play("startup")


func _on_stone_scraping_finished():
	$Pillar/StoneScraping.play()
