extends Node3D

@export var level_scenes : Array[PackedScene]
@export var tank_driver_scene: PackedScene

var selected_level
var player_count
var alive_players = []

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(level_scenes.size() > 0)
	selected_level = level_scenes.pick_random().instantiate()
	print("Selected level:", selected_level)
	add_child(selected_level)
	player_count = Input.get_connected_joypads().size() + 1 # 1 player will use keyboard
	print("Player count: ", player_count)
	spawn_players(player_count)

func spawn_players(player_count):
	for player in range(1, player_count + 1):
		var new_player = tank_driver_scene.instantiate()
		new_player.player_string = str(player)
		var new_player_spawn = selected_level.get_node("PlayerSpawn" + str(player))
		if (new_player_spawn):
			new_player.transform = new_player_spawn.transform
		else: # Couldn't find a spawn point for this player.
			print("WARNING: player ", player, " was spawned in a default location.")
		new_player.die.connect(_on_tank_driver_die)
		new_player.name = "Player" + str(player)
		add_child(new_player)
		alive_players.append(player)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_tank_driver_die(player_num):
	var dead_player = alive_players.find(player_num)
	alive_players.remove_at(dead_player)
	print("Player ", player_num, " has perished!")
	if alive_players.size() <= 1:
		$OneTankLeftTimer.start()

func _on_one_tank_left_timer_timeout():
	if alive_players.size() == 0:
		display_text("Oh, a tie...")
	else:
		$Victory.play()
		display_confetti("Player" + str(alive_players.front()))
		display_text("Player " + str(alive_players.front()) + " good job!!!")
	$OneTankLeftTimer.stop()
	$ResultsTimer.start()

func display_text(text):
	$DisplayText.text = text

func display_confetti(node):
	$Confetti.position = get_node(node).position
	$Confetti.position.y += 5
	$Confetti.emitting = true

func _on_results_timer_timeout():
	get_tree().reload_current_scene()
