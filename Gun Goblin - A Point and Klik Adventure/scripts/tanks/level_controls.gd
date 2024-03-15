extends Node3D

signal changed_scene(String)

@export var tank_drivers : Array[TankDriver]
@export var pillars : Array[TankSelectable]

var game_parameters := {
	"players" : []
}

var joined_players = []
var ready_players = []

# Called when the node enters the scene tree for the first time.
func _ready():
	$CountdownAnimation.play("idle")
	for tank in tank_drivers:
		tank.joined.connect(_on_tank_joined)
		tank.left.connect(_on_tank_left)
	for pillar in pillars:
		pillar.selected.connect(_on_tank_ready)
		pillar.unselected.connect(_on_tank_unready)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if joined_players.size() >= 1 and ready_players.size() >= joined_players.size():
		$CountdownAnimation.play("countdown")
	else:
		$CountdownAnimation.play("idle")


func get_game_parameters() -> Dictionary:
	return game_parameters


func _on_tank_joined(player):
	joined_players.append(player)
	
	
func _on_tank_left(player):
	joined_players.remove_at(joined_players.find(player))
	
	
func _on_tank_ready(player):
	ready_players.append(player)
	player.add_to_group("Ready")
	
func _on_tank_unready(player):
	ready_players.remove_at(ready_players.find(player))
	player.remove_from_group("Ready")

## Called by the CountdownAnimation node
func _finish_countdown():
	#get_tree().change_scene_to_file("res://scenes/tanks/tank_game_master.tscn")
	game_parameters["players"] = ready_players
	changed_scene.emit("PVP")


func _on_out_of_bounds_body_entered(body):
	if body.has_method("out_of_bounds"):
		body.out_of_bounds()
