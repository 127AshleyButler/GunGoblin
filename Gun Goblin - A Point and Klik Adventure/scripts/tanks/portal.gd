class_name Portal
extends Node3D

@export var enemy_scene : PackedScene


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("Spawn")

func set_enemy_spawn(new_enemy : PackedScene):
	enemy_scene = new_enemy

func _spawn_enemy():
	var new_enemy = enemy_scene.instantiate()
	new_enemy.position = $SpawnPosition.global_position
	get_parent().add_child(new_enemy)

