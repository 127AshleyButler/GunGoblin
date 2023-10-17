extends CharacterBody3D

@export var klik_model: MeshInstance3D

const SPEED = 4.0
const JUMP_VELOCITY = 5.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_gravity = gravity
var high_gravity_modifier = 2.0 # Multiplies gravity when jump not held
var is_recording = false
var record_frame_number = 0
# Recording = {Frame number: ["animation", position, rotation]}
var recording = {}
var last_recorded_frame_number = 0
var last_recorded_frame = ["nothing", Vector3(0,0,0), Vector3(0,0,0)]


@onready var model = $CollisionShape3D/klik
@onready var default_model_scale = $CollisionShape3D/klik.scale

func _physics_process(delta):
	if Input.is_action_pressed("jump"):
		current_gravity = gravity
	else:
		current_gravity = gravity * high_gravity_modifier
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= current_gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		model.scale = Vector3(0.5, 1.5, 0.5) * default_model_scale

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
	
	# Handle movement recording
	if (Input.is_action_just_pressed("debug_record_movement")):
		if (!is_recording):
			is_recording = true
			print("Started recording!")
		else: # Toggle recording off & write recording to file
			is_recording = false
			print("Finished recording!")
			write_recording_to_file(recording)
	if (is_recording):
		record_frame()

	# Animate the model squishing
	model.scale = model.scale.lerp(default_model_scale, delta * 10)

# Recording stuff
func record_frame():
	record_frame_number += 1
	var model_rotation = $CollisionShape3D/klik.rotation
	var current_animation = $CollisionShape3D/klik/AnimationPlayer.current_animation
	var current_frame = [current_animation, transform.origin.x, transform.origin.y, transform.origin.z, model_rotation.x, model_rotation.y, model_rotation.z]
	if (current_frame != last_recorded_frame):
		recording[record_frame_number] = current_frame
		last_recorded_frame = current_frame
		last_recorded_frame_number = last_recorded_frame_number

func write_recording_to_file(recorded):
	var recorded_JSON = JSON.stringify(recorded)
	var current_time = Time.get_datetime_dict_from_system()
	#var save_recording = FileAccess.open("user://recording-%02d_%02d%_%02d_%02d" % [current_time.day, current_time.hour, current_time.minute, current_time.second], FileAccess.WRITE)
	var save_recording = FileAccess.open("user://recording", FileAccess.WRITE)
	if (!save_recording):
		print(FileAccess.get_open_error())
	save_recording.store_line(recorded_JSON)
