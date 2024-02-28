extends CharacterBody3D


const SPEED = 12.0 * 1.404
var bounces = 1
## used to determine how powerful of a shot the bullet is
var charge_tier = 0
var charge_tier_speed_bonus = 0
var can_hit_parent = false # Bullets need to bounce at least once before they can hit the tank that spawned them.
var parent_id
var velocity_magnitutde = 0


func _ready():
	$AnimationPlayer.play("idle")
	var direction = basis.z * 1
	calculate_charge_tier_stat_bonus()
	velocity.x = direction.x * SPEED * (1 + charge_tier_speed_bonus)
	velocity.z = direction.z * SPEED * (1 + charge_tier_speed_bonus)


func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		$ExpirationTimer.start()
		velocity = velocity.bounce(collision.get_normal())
		look_at(global_position + velocity, Vector3.UP, true)
		#rotation.x = 0
		#velocity = velocity.normalized() * velocity_magnitutde
		if collision.get_collider().has_method("hit_with_love"):
			#collision.get_collider().hit()
			#hit()
			if (collision.get_collider().get_rid() == parent_id) and can_hit_parent:
				collision.get_collider().hit_with_love()
				vanish()
			elif collision.get_collider().get_rid() != parent_id:
				collision.get_collider().hit_with_love()
				vanish()
		else: # Hit a wall (probably), handle bouncing
			handle_bouncing()


func hit():
	$AnimationPlayer.play("destroy")
	
	
func vanish():
	$AnimationPlayer.play("vanish")


func handle_bouncing():
	if bounces > 0:
		bounces -= 1
		can_hit_parent = true
		$Plink.play()
		if bounces == 0:
			$AnimationPlayer.play("idle_wavering")
	else:
		$AnimationPlayer.play("destroy")
		
		
func calculate_charge_tier_stat_bonus():
	charge_tier_speed_bonus = charge_tier * 0.25
	#scale *= 1 + (min(charge_tier, 4) * 0.15)
	bounces += charge_tier
	if charge_tier >= 3:
		$RocketTrail.show()


func decrement_parent_bullet_count():
	get_parent().decrement_bullet_count()


func _on_expiration_timer_timeout(): # Bullet likely escaped level bounds, destroy it as a failsafe.
	hit()