extends "character.gd"

@export var player_num = 1


func _ready():
	health = 100
	super._ready()

func _physics_process(delta):
	# Handle debug inputs
	if Input.is_action_just_pressed("debug_reload"):
		print("[DEBUG] Reloaded scene!")
		get_tree().reload_current_scene()
	
	super._physics_process(delta)
	# Lessen the gravity if jump is held
	if Input.is_action_pressed("jump"):
		gravity = world_gravity * LOW_GRAVITY_MODIFIER
	else:
		gravity = world_gravity * HIGH_GRAVITY_MODIFIER

	# Handle Jump.
	if Input.is_action_just_pressed("jump"):
		handle_jump()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		#$AnimatedSprite2D.play("default")
		velocity.x = direction * SPEED
	else:
		#$AnimatedSprite2D.stop()
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	
