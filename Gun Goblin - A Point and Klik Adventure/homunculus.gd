extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var recorded_movements = {}
var current_frame_number = 0

func read_recording_data():
	# Reading/Writing from files referenced from: https://docs.godotengine.org/en/4.0/tutorials/io/saving_games.html
	var read_recording = FileAccess.open("user://recording", FileAccess.READ)
	var json_string = read_recording.get_line()
	var json = JSON.new()
	
	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())	
			
	return json.get_data()
	
func _ready():

	recorded_movements = read_recording_data()
	

func _physics_process(delta):
	current_frame_number += 1
	
	if (recorded_movements.has(str(current_frame_number))):	
		var current_frame = recorded_movements[str(current_frame_number)]
		$CollisionShape3D/klik/AnimationPlayer.current_animation = current_frame[0]
		transform.origin = Vector3(current_frame[1], current_frame[2], current_frame[3])
		$CollisionShape3D/klik.rotation = Vector3(current_frame[4], current_frame[5], current_frame[6])
		#var new_vector = string_to_vector(current_frame[1])
		#print(current_frame[1],"type:", typeof(current_frame[1]))

func string_to_vector(input_str):
	var returnVector = Vector3()
	input_str.split(",")
	return returnVector
