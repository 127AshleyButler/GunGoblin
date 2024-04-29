extends Node3D

signal wave_completed

signal all_waves_complete

## How many enemies are allowed to exist at once before the WaveComponent pauses in spawning more
@export var max_enemies : int = 4

@export var portal_spawn_locations : Array[Node3D]

@export var portal_scene : PackedScene

@export var waves : Array[WaveComponent]

# Called when the node enters the scene tree for the first time.
func _ready():
	assert (portal_spawn_locations.size() > 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
