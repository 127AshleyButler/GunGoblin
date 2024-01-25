extends CharacterBody3D

@export_category("Mine Properties")
## How long after placement until the mine will detect tanks driving over it
@export_range(0, 20, 0.5, "or_greater", "or_less") var mine_activation_time = 1
var mine_active = false
var airborne = true
const SPEED = 6.0
var charge_tier = 0
var charge_tier_speed_bonus = 0
var charge_tier_height_bonus = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	$ActivationTimer.wait_time = mine_activation_time
	$AnimationPlayer.play("idle_unprimed")
	var direction = basis.z * 1
	calculate_charge_tier_stat_bonus()
	velocity.x = direction.x * SPEED * (1 + charge_tier_speed_bonus)
	velocity.z = direction.z * SPEED * (1 + charge_tier_speed_bonus)
	velocity.y = 3 * (1 + charge_tier_height_bonus)

func _physics_process(delta):
	if not airborne:
		return
		
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		airborne = false
		$ActivationTimer.start()
		$AnimationPlayer.play("landing")

func hit():
	$AnimationPlayer.play("destroy")

func _on_detection_radius_body_entered(body):
	if mine_active:
		$AnimationPlayer.play("destroy")

func _on_activation_timer_timeout():
	if mine_active:
		return
	mine_active = true
	$DetectionRadius.monitoring = true
	$AnimationPlayer.play("priming")

func _on_explosion_radius_body_entered(body):
	if body.has_method("hit"):
		body.hit()
	if body.is_in_group("Debris"):
		var impulse_direction = position - body.position
		body.apply_impulse(body.position, impulse_direction)

func _on_explosion_radius_area_entered(area):
	if area.has_method("hit"):
		area.hit()

func calculate_charge_tier_stat_bonus():
	charge_tier_speed_bonus = min(charge_tier, 2) * 0.4
	charge_tier_height_bonus = (min(charge_tier, 4)) * 0.6
	#scale *= 1 + (charge_tier * 0.15)

func decrement_parent_mine_count():
	get_parent().decrement_mine_count()
