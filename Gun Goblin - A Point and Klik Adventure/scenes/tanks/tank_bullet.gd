extends CharacterBody3D


const SPEED = 12.0
var bounces = 1
## used to determine how powerful of a shot the bullet is
var charge_shot_time = 0

func _ready():
	var direction = basis.z * 1
	velocity.x = direction.x * SPEED * (1 + charge_shot_time)
	velocity.z = direction.z * SPEED * (1 + charge_shot_time)

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		look_at(global_position + velocity, Vector3.UP, true)
		if collision.get_collider().has_method("hit"):
			collision.get_collider().hit()
			hit()
		else: # Hit a wall (probably), handle bouncing
			handle_bouncing()

func hit():
	$AnimationPlayer.play("destroy")

func handle_bouncing():
	if bounces > 0:
		bounces -= 1
		$Plink.play()
	else:
		$AnimationPlayer.play("destroy")
