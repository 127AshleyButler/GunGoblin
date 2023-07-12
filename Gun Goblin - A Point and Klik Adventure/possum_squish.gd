extends Node3D

@onready var anim = $AnimationPlayer
@onready var speech = $Speech

@export var text_to_say: String

var current_text = ""
var is_talking = false
var text_delay = 0.1 # delay in seconds per letter
var current_text_delay = 0
var finished_talking = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	handle_talking(delta)

func handle_talking(delta):
	if (is_talking):
		current_text_delay -= delta
		if (current_text_delay <= 0):
			current_text_delay = text_delay
			var newest_letter = text_to_say.substr(current_text.length(), 1)
			current_text += newest_letter
			speech.text = current_text
			if (current_text.length() >= text_to_say.length()):
				is_talking = false
				finished_talking = true

func _on_talking_radius_body_entered(body):
	if (finished_talking):
		return
	anim.play("PossumAction")
	is_talking = true


func _on_animation_player_animation_finished(anim_name):
	# Keep repeating the talking animation until the NPC finished talking.
	if (finished_talking):
		anim.stop()
	else:
		anim.play("PossumAction")
