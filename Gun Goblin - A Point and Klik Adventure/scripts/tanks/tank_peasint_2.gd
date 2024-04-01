extends Node3D


func play_animation(animation_name: String):
	match animation_name:
		"shoot":
			$AnimationPlayer.play("Shoot_001")
			$AnimationPlayer.seek(0)
