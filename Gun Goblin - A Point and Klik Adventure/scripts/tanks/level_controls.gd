extends Node3D

@export var tank_drivers : Array[TankDriver]
@export var pillars : Array[TankSelectable]

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


func _on_tank_joined(player_num):
	joined_players.append(player_num)
	
	
func _on_tank_left(player_num):
	joined_players.remove_at(joined_players.find(player_num))
	
	
func _on_tank_ready(player_num):
	ready_players.append(player_num)
	
	
func _on_tank_unready(player_num):
	ready_players.remove_at(ready_players.find(player_num))

## Called by the CountdownAnimation node
func _finish_countdown():
	get_tree().change_scene_to_file("res://scenes/tanks/tank_game_master.tscn")
