extends Node

enum GameMode {TITLE_SCREEN, CONTROLS, PVP, CAMPAIGN, }

@export var initial_scene : PackedScene
@export var controls_scene : PackedScene
@export var pvp_scene : PackedScene

var current_scene
var _current_mode = GameMode.CONTROLS

# Called when the node enters the scene tree for the first time.
func _ready():
	current_scene = initial_scene.instantiate()
	current_scene.changed_scene.connect(_on_change_game_mode)
	add_child(current_scene)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func transfer_game_parameters(old_scene: Node3D, new_scene: Node3D) -> void:
	if (
			old_scene.has_method("get_game_parameters")
			and new_scene.has_method("get_game_parameters")
	):
		# Swap players to new scene
		for player in old_scene.get_children():
			if player.is_in_group("TankDriver") and player.is_in_group("Ready"):
				player.reparent(new_scene)
				new_scene.game_parameters["players"].append(player)
	
# Called by children game modes' signals
func _on_change_game_mode(new_mode : String) -> void :
	var new_scene
	match new_mode:
		"PVP":
			new_scene = pvp_scene.instantiate()
		var unknown_mode:
			print("WARNING: Invalid mode:", unknown_mode)
	_swap_scenes(current_scene, new_scene)
	
	
func _swap_scenes(old_scene, new_scene):
	transfer_game_parameters(old_scene, new_scene)
	add_child(new_scene)
	remove_child(old_scene)
	old_scene.queue_free()
	current_scene = new_scene
	current_scene.changed_scene.connect(_on_change_game_mode)
