## tank_selectable.gd
## a node used for selecting things as the player tanks
## Only one tank can be assigned to a selectable at a time.
class_name TankSelectable
extends Node3D

signal selected(player_num)
signal unselected(player_num)

@export var color_override : Color
@export_multiline var text_override : String
@export var particle_mesh_override : Mesh
@export var model : Node3D
## How far this pillar extracts when selected
@export var extracted_length = 5

var selected_by
var extraction_speed = 0.5
var current_extraction = 0
var _starting_y_position
var target_position = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$GPUParticles3D.draw_pass_1 = particle_mesh_override
	$GPUParticles3D.draw_pass_1.material.albedo_color = color_override
	$Icon/Label3D.modulate = color_override
	$Icon/Label3D.outline_modulate = color_override.darkened(0.5)
	$Icon/Label3D.text = text_override
	_starting_y_position = model.position.y


func _physics_process(delta):
	if not selected_by:
		$Icon.position = Vector3.ZERO
		target_position = 0
		current_extraction = move_toward(current_extraction, target_position, delta)
		model.position.y = current_extraction + _starting_y_position
	else: # This selectable has been selected
		$Icon.global_position = selected_by.global_position + Vector3(0, 5, 0)
		target_position = extracted_length
		current_extraction = move_toward(current_extraction, target_position, delta)
		model.position.y = current_extraction + _starting_y_position
	
	if current_extraction != target_position: # if this is moving
		$Sliding.play()
	else: # if this has stopped
		$Sliding.stop()


func _on_enter_hitbox_body_entered(body):
	if not selected_by:
		selected_by = body
		selected.emit(int(body.player_num))


func _on_exit_hitbox_body_exited(body):
	if body == selected_by:
		selected_by = null
		unselected.emit(int(body.player_num))
