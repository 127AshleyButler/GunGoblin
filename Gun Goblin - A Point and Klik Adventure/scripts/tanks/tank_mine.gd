extends CharacterBody3D

@export_category("Mine Properties")
## How long after placement until the mine will detect tanks driving over it
@export_range(0, 20, 0.5, "or_greater", "or_less") var mine_activation_time = 1
var mine_active = false
var is_shot = false # whether or not this mine was launched from a charge shot
const SPEED = 6.0
var charge_tier = 0
var charge_tier_speed_bonus = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	$ActivationTimer.wait_time = mine_activation_time
	$ActivationTimer.start()
	$AnimationPlayer.play("idle")
	var direction = basis.z * 1
	calculate_charge_tier_stat_bonus()
	velocity.x = direction.x * SPEED * (1 + charge_tier_speed_bonus)
	velocity.z = direction.z * SPEED * (1 + charge_tier_speed_bonus)
	velocity.y = 3 * (1 + charge_tier_speed_bonus)

func _physics_process(delta):
	if not is_shot:
		return
		
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		is_shot = false

func hit():
	$AnimationPlayer.play("destroy")

func _on_detection_radius_body_entered(body):
	if mine_active:
		$AnimationPlayer.play("destroy")

func _on_activation_timer_timeout():
	mine_active = true
	$DetectionRadius.monitoring = true

func _on_explosion_radius_body_entered(body):
	if body.has_method("hit"):
		body.hit()

func _on_explosion_radius_area_entered(area):
	if area.has_method("hit"):
		area.hit()

func calculate_charge_tier_stat_bonus():
	charge_tier_speed_bonus = charge_tier * 0.4
	#scale *= 1 + (charge_tier * 0.15)
