extends Node3D


func play_animation(animation_name: String):
	$AnimationPlayer.play(animation_name)
	#$AnimationPlayer.seek(0)
