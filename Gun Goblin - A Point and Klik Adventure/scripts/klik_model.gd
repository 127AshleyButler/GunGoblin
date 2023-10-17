extends Node3D

@onready var anim = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if (input_dir):
		anim.play("run")
		var direction = (Vector3(input_dir.x, 0, input_dir.y)).normalized()
		look_at(global_transform.origin + direction, Vector3.UP, true)
	else: anim.play("idle")
