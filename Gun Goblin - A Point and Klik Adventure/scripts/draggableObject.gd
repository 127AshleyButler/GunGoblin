# Based on Test Shapes Godot example scene

extends RigidBody3D


const MOUSE_DELTA_COEFFICIENT = 0.01
const CAMERA_DISTANCE_COEFFICIENT = 0.2
const GRAB_STRENGTH = 25

var _picked = false
var _last_mouse_pos = Vector2.ZERO
var _mouse_pos = Vector2.ZERO

@export var min_theremin_pitch = 0.5
@export var max_theremin_pitch = 2.5
@export var theramin_pitch_scale = 0.05 # The scale at which distance affects theramin pitch
@export var theramin_pitch_speed = 1.5 # The speed at which the theramin's pitch changes
var current_pitch = 1

@onready var player = get_tree().get_nodes_in_group("player")[0]

func _ready():
	input_ray_pickable = true


func _input(event):
	var mouse_event = event as InputEventMouseButton
	if mouse_event and not mouse_event.pressed:
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_picked = false
			Events.emit_signal("grabbing_object", false)

	var mouse_motion = event as InputEventMouseMotion
	if mouse_motion:
		_mouse_pos = mouse_motion.position


func _input_event(_viewport, event, _click_pos, _click_normal, _shape_idx):
	var mouse_event = event as InputEventMouseButton
	if mouse_event and mouse_event.pressed:
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_picked = true
			Events.emit_signal("grabbing_object", "true")
			_mouse_pos = mouse_event.position
			_last_mouse_pos = _mouse_pos


func _physics_process(delta):
	if _picked:
		if ($AudioStreamPlayer3D.playing):
			$AudioStreamPlayer3D.stream_paused = false
		else:
			$AudioStreamPlayer3D.play()
	
		if (player):
			var distance = position.distance_squared_to(player.cursor.position)
			# Update pitch of the theramin based on how far the cursor is
			var target_pitch = clampf(distance * theramin_pitch_scale, min_theremin_pitch, max_theremin_pitch)
			$AudioStreamPlayer3D.pitch_scale = lerpf(current_pitch, target_pitch, theramin_pitch_speed * delta)
			current_pitch = $AudioStreamPlayer3D.pitch_scale
			
			# Apply force to the object
			var direction = position.direction_to(player.cursor.position)
			apply_force(direction * distance * delta * GRAB_STRENGTH)
			#linear_velocity = direction * distance * delta * GRAB_STRENGTH
			
	else:
		$AudioStreamPlayer3D.stream_paused = true


func _on_input_event(camera, event, position, normal, shape_idx):
	pass # Replace with function body.
