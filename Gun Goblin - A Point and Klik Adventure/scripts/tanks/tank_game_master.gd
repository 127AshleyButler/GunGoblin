extends Node3D

@export var level_scenes : Array[PackedScene]
@export var tank_driver_scene: PackedScene

var selected_level
var player_count
var alive_players = []
var scores = {}
var player_objects = []
var round_over = false

# Called when the node enters the scene tree for the first time.
func _ready():
	initiate_players()
	new_round()

func select_random_level():
	if (selected_level):
		selected_level.queue_free()
	assert(level_scenes.size() > 0)
	selected_level = level_scenes.pick_random().instantiate()
	print("Selected level:", selected_level)
	add_child(selected_level)

func initiate_players():
	player_count = Input.get_connected_joypads().size() + 1 # 1 player will use keyboard
	print("Player count: ", player_count)
	for player_num in range(1, player_count + 1):
		var new_player = tank_driver_scene.instantiate()
		new_player.player_num = str(player_num)
		new_player.die.connect(_on_tank_driver_die)
		new_player.name = "Player" + str(player_num)
		new_player.update_label(str(player_num))
		if new_player.name in scores:
			print("This player exists already")
		scores[new_player.name] = 0
		add_child(new_player)
		player_objects.append(new_player)
		
		
func respawn_players():
	var spawn_locations = ["PlayerSpawn1", "PlayerSpawn2", "PlayerSpawn3", "PlayerSpawn4"]
	spawn_locations.shuffle()
	alive_players = []
	for player in player_objects:
		alive_players.append(int(player.player_num))
		player.set_physics_process(true)
		var new_player_spawn = selected_level.get_node(spawn_locations.pop_front())
		if (new_player_spawn):
			player.transform = new_player_spawn.transform
		else: # Couldn't find a spawn point for this player.
			print("WARNING: player ", player.name, " was spawned in a default location.")
		player._ready()
		
func new_round():
	round_over = false
	$Confetti.restart()
	$Confetti.emitting = false
	select_random_level()
	respawn_players()
	display_text("Ready?")
	$Ready.play()
	$RoundStartTimer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_tank_driver_die(player_num):
	if (round_over):
		print("Player ", player_num, " has perished, but the round was already over.")
		return
	var dead_player = alive_players.find(player_num)
	alive_players.remove_at(dead_player)
	print("Player ", player_num, " has perished!")
	if alive_players.size() <= 1:
		$OneTankLeftTimer.start()

func _on_one_tank_left_timer_timeout():
	round_over = true
	if alive_players.size() == 0:
		display_text("Oh, a tie...")
	else:
		$Victory.play()
		increment_score("Player" + str(alive_players.front()))
		display_confetti("Player" + str(alive_players.front()))
		display_text("Player " + str(alive_players.front()) + " good job!!!")
	$OneTankLeftTimer.stop()
	$NewRoundTimer.start()

func increment_score(playerString):
	scores[playerString] += 1
	get_node("Scores/" + playerString).text = get_node("Scores/" + playerString).text.substr(0,4) + str(scores[playerString])
	print(scores)

func display_text(text, duration = 0):
	$DisplayText.text = text
	if duration > 0:
		$TextDurationTimer.wait_time = duration
		$TextDurationTimer.start()

func display_confetti(node):
	$Confetti.restart()
	$Confetti.position = get_node(node).position
	$Confetti.position.y += 5
	$Confetti.emitting = true

func _on_new_round_timer_timeout():
	new_round()

func _on_round_start_timer_timeout():
	display_text("Go!", 1.5)
	$Go.play()
	get_tree().call_group("TankDriver", "start_of_round")

func _on_text_duration_timer_timeout():
	display_text("")
