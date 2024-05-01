extends Node3D

signal wave_completed

signal all_waves_complete

@export_category("Enemies")
@export var orange_arm_man_scene : PackedScene

@export_category("Variables")
## How many enemies are allowed to exist at once before the WaveComponent pauses in spawning more
@export var max_enemies : int = 4

@export var portal_spawn_locations : Array[Node3D]

@export var portal_scene : PackedScene

@export var enemy_types : Dictionary

@export var waves : Dictionary

var _wave_number : int = -1
var _current_wave : Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	try_spawning()


func try_spawning() -> bool:
	if _current_wave.is_empty():
		if not _load_next_wave():
			# No more enemies to spawn
			return false
	_spawn(_current_wave.pop_front())
	return true


func _load_next_wave() -> bool:
	_wave_number += 1
	if waves.has(_wave_number):
		# Next wave exists, load it into current wave
		_current_wave = waves[_wave_number]
		return true
	# No more waves, return false
	return false


func _spawn(enemyName : StringName):
	print("Spawning: ", enemyName)
	var new_portal = portal_scene.instantiate() as Portal
	if not enemy_types.has(enemyName):
		print("Error, [", enemyName, "] not in enemy types.")
		return
	new_portal.enemy_scene = enemy_types[enemyName]
	new_portal.position = portal_spawn_locations.pick_random().global_position
	add_child(new_portal)
