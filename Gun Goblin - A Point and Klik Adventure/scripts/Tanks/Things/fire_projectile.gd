extends RigidBody3D

var launch_force = 5.0


# Called when the node enters the scene tree for the first time.
func _ready():
	$CollisionShape3D/AnimatedSprite3D.play("default")
	$AnimationPlayer.play("spawn")
	apply_central_impulse(launch_force * ($LaunchDirection.global_position - global_position))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_lifetime_timeout():
	$AnimationPlayer.play("expire")


func _on_hitbox_area_entered(area):
	if area.has_method("hit"):
		area.hit()


func _on_hitbox_body_entered(body):
	if body.has_method("hit"):
		body.hit()
