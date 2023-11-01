extends SpringArm3D

@export var mouse_sensitivity:= 0.05
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		rotation_degrees.x -= event.relative.y * mouse_sensitivity
		rotation_degrees.x = clamp(rotation_degrees.x, -90.0, 30.0)
		
		rotation_degrees.y -= event.relative.x * mouse_sensitivity
		rotation_degrees.y = wrapf(rotation_degrees.y, 0.0, 360.0)
