extends CharacterBody3D

@export_category("Mine Properties")
## How long after placement until the mine will detect tanks driving over it
@export_range(0, 20, 0.5, "or_greater", "or_less") var mine_activation_time = 1
var mine_active = false
var mine_about_to_explode = false
var airborne = true
var launched = false
const SPEED = 6.0
var charge_tier = 0
var charge_tier_speed_bonus = 0
var charge_tier_height_bonus = 0
var can_assimilate = true # Determines if mine can absorb other mines
var can_be_assimilated = true # Used to determine if mine can merge with others
var mines_assimilated = 0
var mine_number = 0 # Used to determine priority of mine assimilation; older mines absorb younger ones.

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	$ActivationTimer.wait_time = mine_activation_time
	$AnimationPlayer.play("idle_unprimed")
	var direction = basis.z * 1
	if launched:
		calculate_charge_tier_stat_bonus()
		velocity.x = direction.x * SPEED * (1 + charge_tier_speed_bonus)
		velocity.z = direction.z * SPEED * (1 + charge_tier_speed_bonus)
		velocity.y = 3 * (1 + charge_tier_height_bonus)


func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	var collision = move_and_collide(velocity * delta)
	if collision and not mine_about_to_explode and airborne:
		velocity = velocity.slide(collision.get_normal())
		airborne = false
		$ActivationTimer.start()
		$AnimationPlayer.play("landing")


func hit():
	$AnimationPlayer.speed_scale = 1.75
	get_ready_to_explode()
	
	
func _on_detection_radius_body_entered(body):
	if not mine_active or body == self:
		return
	if body.is_in_group("Mine"):
		if can_assimilate and body.can_be_assimilated and mine_number < body.mine_number:
			body.dissolve()
			increase_scale(body.mines_assimilated + 1)
	else:
		get_ready_to_explode()
		
		
func dissolve():
	can_assimilate = false
	can_be_assimilated = false
	mine_active = true
	$AnimationPlayer.play("dissolve")
		
		
func increase_scale(amount = 1):
	if mine_about_to_explode:
		return
	scale += Vector3(0.1, 0.1, 0.1) * amount
	mines_assimilated += amount
	$AnimationPlayer.play("preview_explosion_radius")
	$Primed.pitch_scale -= 0.05 * amount
	$Explosion.pitch_scale -= 0.01 * amount
		
func get_ready_to_explode():
	#$AnimationPlayer.speed_scale = 1 / (1 + mines_assimilated)
	can_assimilate = false
	can_be_assimilated = false
	if mine_about_to_explode:
		return
	$AnimationPlayer.play("blinking")
	mine_about_to_explode = true


func _on_activation_timer_timeout():
	if mine_active:
		return
	mine_active = true
	$DetectionRadius.monitoring = true
	if not mine_about_to_explode:
		$AnimationPlayer.play("priming")


func _on_explosion_radius_body_entered(body):
	if body.has_method("hit"):
		body.hit()
	elif body.is_in_group("Debris"):
		var impulse_direction = position - body.position
		body.apply_impulse(body.position, impulse_direction)
	elif body.is_in_group("SpikeTop"):
		body._on_hurtbox_body_entered(self, 2)


func _on_explosion_radius_area_entered(area):
	if area.has_method("hit"):
		area.hit()


func calculate_charge_tier_stat_bonus():
	charge_tier_speed_bonus = min(charge_tier, 2) * 0.4
	charge_tier_height_bonus = (min(charge_tier, 4)) * 0.6
	#scale *= 1 + (charge_tier * 0.15)


func decrement_parent_mine_count():
	get_parent().decrement_mine_count()


func _on_expiration_timer_timeout(): # Mine failed to land in a reasonable amount of time, destroy it as a failsafe
	hit()
