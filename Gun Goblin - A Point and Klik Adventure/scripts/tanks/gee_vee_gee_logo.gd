extends CharacterBody3D

## How fast this travels
@export var speed = 12.0
@export var copy_delay = 0.1
var bounces = 1

var current_modulation = 0
var modulation_colors = [Color(0, 0.576, 1), Color(0, 0.651, 0.635), Color(0.114, 0.686, 0),
		Color(0.722, 0.533, 0), Color(0.937, 0.353, 0), Color(1, 0.216, 0.341),
		Color(0.961, 0, 0.78), Color(0.694, 0.376, 1)]
var current_copy_delay = 0
var current_copy = 0
@onready var copy_count = $Copies.get_child_count()

func _ready():
	var direction = basis.z * 1
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		if collision.get_collider().has_method("hit"):
			collision.get_collider().hit()
		advance_modulation()
	current_copy_delay -= delta
	if current_copy_delay <= 0:
		current_copy_delay += copy_delay
		update_copies()
		
func advance_modulation():
	$Plink.play()
	current_modulation = (current_modulation + 1) % modulation_colors.size()
	$Logo.modulate = modulation_colors[current_modulation]

func update_copies():
	var current_copy_node = get_node("Copies/Copy" + str(current_copy))
	current_copy_node.global_position = global_position
	current_copy_node.modulate = $Logo.modulate
	current_copy_node.transparency = 0
	current_copy = (current_copy + 1) % copy_count
	for copy in range(copy_count):
		current_copy_node = get_node("Copies/Copy" + str(copy))
		current_copy_node.transparency += 0.2
