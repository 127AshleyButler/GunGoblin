extends Control
@onready var _point = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready():
	_point.play("idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = get_viewport().get_mouse_position()
