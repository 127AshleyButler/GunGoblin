extends Node3D

@onready var anim = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _getWASD():
	if Input.is_action_pressed("move_down"):
		return true;
	if Input.is_action_pressed("move_left"):
		return true;
	if Input.is_action_pressed("move_right"):
		return true;
	if Input.is_action_pressed("move_up"):
		return true;
	return false;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (_getWASD() == true):
		anim.play("run")
	else: anim.play("idle")
	
