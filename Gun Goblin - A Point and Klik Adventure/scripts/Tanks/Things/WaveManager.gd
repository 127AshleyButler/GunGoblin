extends Node3D

signal wave_completed

signal all_waves_complete

signal enemy_died

signal all_enemies_dead

@export_category("Enemies")
@export var orange_arm_man_scene : PackedScene

@export_category("Variables")
## How many enemies are allowed to exist at once before the WaveComponent pauses in spawning more
@export var max_enemies : int = 4

@export var portal_spawn_locations : Array[Node3D]

@export var portal_scene : PackedScene

@export var enemy_types : Dictionary

@export var waves : Dictionary

var _wave_number : int = 0
var _current_wave : Array = []
var _enemy_count : int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	_load_next_wave()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#try_spawning()
	pass


func _load_next_wave() -> bool:
	# First, if there are any enemies, wait for them to die
	if _enemy_count > 0:
		await _wait_for_no_enemies_left()
	_wave_number += 1
	if $AnimationPlayer.has_animation("Wave_" + str(_wave_number)):
		# Next wave exists, play it.
		wave_completed.emit()
		$AnimationPlayer.play("Wave_" + str(_wave_number))
		return true
	# No more waves, return false
	return false


func _spawn(enemyName : StringName):
	print("Spawning: ", enemyName)
	var new_portal = portal_scene.instantiate() as Portal
	#var new_portal = portal_scene.instantiate()
	if not enemy_types.has(enemyName):
		print("Error, [", enemyName, "] not in enemy types.")
		return
	if _enemy_count >= max_enemies:
		$AnimationPlayer.pause()
		# Too many alive enemies! We wait for one to die so that there's more room.
		await _wait_for_enemy_death()
		# An enemy died, there is now room to spawn more.
		$AnimationPlayer.play()
	new_portal.enemy_scene = enemy_types[enemyName]
	new_portal.position = portal_spawn_locations.pick_random().global_position
	new_portal.enemy_spawned.connect(_on_enemy_spawned)
	add_child(new_portal)
	_enemy_count += 1


## Called by the AnimationPlayer at the start of waves
func _change_max_enemies(new_value):
	max_enemies = new_value


func _wait_for_enemy_death():
	await enemy_died


func _wait_for_no_enemies_left():
	await all_enemies_dead


func _on_enemy_spawned(new_enemy : Enemy):
	new_enemy.die.connect(_on_enemy_die)
	
	
func _on_enemy_die():
	enemy_died.emit()
	_enemy_count -= 1
	if _enemy_count <= 0:
		all_enemies_dead.emit()


func _on_animation_player_animation_finished(anim_name):
	print("Completed Wave: ", anim_name)
	if not await _load_next_wave():
		print("All waves complete")
		all_waves_complete.emit()
