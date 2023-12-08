extends Control
@onready var _point = $AnimatedSprite2D
var is_idle = true
var hovering_over = "nothing"
var grabbing_object = false

# Called when the node enters the scene tree for the first time.
func _ready():
	_point.play("idle")
	Events.connect("hovered_over_object", _on_hovered_over_object)
	Events.connect("grabbing_object", _on_grab_ungrab_object)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = get_viewport().get_mouse_position()
	update_animation_parameters()
	
func update_animation_parameters():
	$AnimationTree["parameters/conditions/idle"] = is_idle

func _on_hovered_over_object(property):
	match property:
		"draggable":
			hovering_over = "draggable"
		"inspectable":
			hovering_over = "inspectable"
		_:
			# No specific property
			hovering_over = "nothing"

func _on_grab_ungrab_object(is_grabbing):
	grabbing_object = is_grabbing
