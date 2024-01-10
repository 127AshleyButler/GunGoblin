# Based on Test Shapes Godot example scene

extends RigidBody3D


const MOUSE_DELTA_COEFFICIENT = 0.01
const CAMERA_DISTANCE_COEFFICIENT = 0.2
const GRAB_STRENGTH = 25

var _picked = false
var _last_mouse_pos = Vector2.ZERO
var _mouse_pos = Vector2.ZERO

#@export var collision_scene : CollisionShape3D

@export var line_radius = 0.5
@export var line_resolution = 10

@export var min_theremin_pitch = 0.5
@export var max_theremin_pitch = 2.0
@export var theramin_pitch_scale = 0.05 # The scale at which distance affects theramin pitch
@export var theramin_pitch_speed = 4.0 # The speed at which the theramin's pitch changes
var current_pitch = 1
var distance

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
	if _picked: # Object is being dragged
		if ($AudioStreamPlayer3D.playing):
			$AudioStreamPlayer3D.stream_paused = false
		else:
			$AudioStreamPlayer3D.play()
	
		if (player):
			distance = position.distance_squared_to(player.cursor.position)
			# Update pitch of the theramin based on how far the cursor is
			var target_pitch = clampf(distance * theramin_pitch_scale, min_theremin_pitch, max_theremin_pitch)
			$AudioStreamPlayer3D.pitch_scale = lerpf(current_pitch, target_pitch, theramin_pitch_speed * delta)
			current_pitch = $AudioStreamPlayer3D.pitch_scale
			
			
			
			
			# Apply force to the object
			var direction = position.direction_to(player.cursor.position)
			apply_force(direction * distance * delta * GRAB_STRENGTH)
			linear_damp = 10 * ((150 - distance) / 100)
			#print("Distance:", distance, " damp:", linear_damp)
			
			# Update the beam connecting from this object to Point
			$BeamPath.curve.set_point_position(0, position)
			$BeamPath.curve.set_point_position(1, player.cursor.position)
			render_line()
	else: # object not currently being dragged
		linear_damp = 0
		$AudioStreamPlayer3D.stream_paused = true
		$CSGPolygon3D.hide()
	# Move parent with draggable object
	#get_parent().position = global_position


func _on_input_event(camera, event, position, normal, shape_idx):
	pass # Replace with function body.

func render_line():
	var circle = PackedVector2Array()
	for degree in line_resolution:
		var x = line_radius * sin(PI * 2 * degree / line_resolution)
		var y = line_radius * cos(PI * 2 * degree / line_resolution)
		var coords = Vector2(x, y)
		circle.append(coords)
	$CSGPolygon3D.polygon = circle
	$CSGPolygon3D.show()
