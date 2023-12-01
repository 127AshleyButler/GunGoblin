extends CharacterBody3D

@export var team = NO_TEAM # This character's team (e.g., teamed characters can't usually hurt each other)

@onready var world_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var gravity = world_gravity

signal die

const SPEED = 30.0
const JUMP_VELOCITY = 30.0
const JUMP_GRACE_PERIOD = 0.2 # Time in seconds to allow character to jump right after they slip off a ledge
const WALL_SLIDE_VELOCITY = 15.0 # Speed in which the player moves down when sliding on walls
const HIGH_GRAVITY_MODIFIER = 15.0 # How fast the player falls when they are not holding jump
const LOW_GRAVITY_MODIFIER = 7.5 # How much to multiply the gravity by when the player holds the jump key
const NO_TEAM = "NO_TEAM"

var air_time = 0 # Time in seconds character is airborne
var health = 100.0 # How much punishment a character can take before they've had enough for the day
var max_health


func _ready():
	$HealthBar.texture = $HealthBar/SubViewport.get_texture()
	# Initialize health bar
	max_health = health
	update_health(health, max_health)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
		air_time += delta
	else:
		air_time = 0

	# Handle Wall Sliding
	if is_touching_wall():
		# Wall Slide
		if velocity.y > 0:
			velocity.y = -WALL_SLIDE_VELOCITY

	move_and_slide()

func is_touching_wall():
	if $WallClingRight.is_colliding():
		return 1
	if $WallClingLeft.is_colliding():
		return -1
	return false

func take_damage(damage_amount):
	health -= damage_amount
	update_health(health, max_health)
	if (health <= 0):
		play_death_animation()
		
func update_health(h, mh):
	$HealthBar/SubViewport/HealthBar.value = h
	$HealthBar/SubViewport/HealthBar.max_value = mh
	
func play_death_animation():
	perish()
	
func perish():
	queue_free()

func handle_jump():
	print("Is on floor?", is_on_floor(), "air time?", air_time)
	# Handle Jump.
	if is_on_floor() or air_time < JUMP_GRACE_PERIOD:
		velocity.y = JUMP_VELOCITY
		air_time = JUMP_GRACE_PERIOD

	# Handle Wall Jumps
	if is_touching_wall():
		# Wall Jump
		velocity.y = JUMP_VELOCITY

