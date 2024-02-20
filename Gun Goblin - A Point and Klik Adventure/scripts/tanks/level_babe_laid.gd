extends Node3D


var spikes_active = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer2.play("initial")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_spike_activation_timer_timeout():
	spikes_active += 1
	$AnimationPlayer2.play("activate_spike" + str(spikes_active))
