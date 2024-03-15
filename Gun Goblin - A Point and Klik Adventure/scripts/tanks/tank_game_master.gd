extends Node3D

signal changed_scene(String)

@export var level_scenes : Array[PackedScene]
@export var tank_driver_scene: PackedScene

var game_parameters := {
	"players" : []
}


var selected_level
var player_count
var alive_players = []
var unloved_players = []
var scores = {}
var round_over = false
var level_num = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	DebugTools.next_level.connect(next_level)
	DebugTools.prev_level.connect(prev_level)
	initiate_players()
	select_random_level()
	new_round()


func get_game_parameters() -> Dictionary:
	return game_parameters


func select_random_level():
	level_num = randi() % level_scenes.size()
	select_level(level_num)
	new_round()


func next_level():
	level_num += 1
	select_level(level_num)
	new_round()
	
	
func prev_level():
	level_num -= 1
	select_level(level_num)
	new_round()


func select_level(level = 0):
	if (selected_level):
		selected_level.queue_free()
	assert(level_scenes.size() > 0)
	level %= level_scenes.size()
	level_num = level
	selected_level = level_scenes[level].instantiate()
	# If the level is cavernous, enable a reverb effect.
	AudioServer.set_bus_effect_enabled(1, 0, selected_level.is_in_group("Cavernous"))
	print("Selected level:", selected_level)
	add_child(selected_level)


func initiate_players():
	if game_parameters["players"].size() <= 0:
		print("Creating new players from scratch")
		create_new_players()
	else:
		print("Found existing players from game parameters")
		player_count = game_parameters["players"].size()
		var player_num = 1
		for player in game_parameters["players"]:
			#player.player_num = str(player_num)
			player.killed.connect(_on_tank_driver_killed)
			player.loved.connect(_on_tank_driver_loved)
			player.name = "Player" + str(player.player_num)
			if player.name in scores:
				print("This player exists already")
			scores[player.player_num] = 0
			_update_score_label(get_node("Scores/UnusedPlayer" + str(player_num)), player)
			player_num += 1
		

func create_new_players():
	player_count = Input.get_connected_joypads().size() + 1 # 1 player will use keyboard
	print("Player count: ", player_count)
	for player_num in range(1, player_count + 1):
		var new_player = tank_driver_scene.instantiate()
		new_player.player_num = str(player_num)
		new_player.killed.connect(_on_tank_driver_killed)
		new_player.loved.connect(_on_tank_driver_loved)
		new_player.name = "Player" + str(player_num)
		new_player.update_label("P" + str(player_num) + "\nV")
		if new_player.name in scores:
			print("This player exists already")
		scores[new_player.player_num] = 0
		add_child(new_player)
		game_parameters["players"].append(new_player)
		
		
func respawn_players():
	var spawn_locations = ["PlayerSpawn1", "PlayerSpawn2", "PlayerSpawn3", "PlayerSpawn4"]
	spawn_locations.shuffle()
	alive_players = []
	unloved_players = []
	for player in game_parameters["players"]:
		alive_players.append(int(player.player_num))
		unloved_players.append(int(player.player_num))
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
	respawn_players()
	display_text("Ready?")
	$Ready.play()
	$RoundStartTimer.start()
	$OneTankLeftTimer.stop()
	$NewRoundTimer.stop()


func _on_tank_driver_killed(player_num):
	if (round_over):
		print("Player ", player_num, " has perished, but the round was already over.")
		return
	alive_players.remove_at(alive_players.find(player_num))
	unloved_players.remove_at(unloved_players.find(player_num))
	print("Player ", player_num, " has perished!")
	if alive_players.size() <= 1:
		$OneTankLeftTimer.start()
		
		
func _on_tank_driver_loved(player_num):
	if (round_over):
		print("Player ", player_num, " received love, but the round was already over.")
		return
	print("Player ", player_num, " received love!")
	unloved_players.remove_at(unloved_players.find(player_num))
	if unloved_players.size() <= 0:
		$OneTankLeftTimer.start()


func _on_one_tank_left_timer_timeout():
	round_over = true
	if alive_players.size() == 0:
		display_text("Oh, a tie...")
	elif unloved_players.size() <= 0 and alive_players.size() >= 2:
		display_text("Love wins!")
		for player in alive_players:
			increment_score(str(player))
	else:
		$Victory.play()
		assert(alive_players.size() == 1)
		increment_score(str(alive_players.front()))
		display_confetti("Player" + str(alive_players.front()))
		display_text("Player " + str(alive_players.front()) + " good job!!!")
	$OneTankLeftTimer.stop()
	$NewRoundTimer.start()


func increment_score(playerString):
	scores[playerString] += 1
	get_node("Scores/Player" + playerString).text = get_node("Scores/Player" + playerString).text.substr(0,4) + str(scores[playerString])
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


func _update_score_label(score, player):
	var player_label = player.get_label()
	score.text = player_label.text[0] + " : "
	score.modulate = player_label.modulate
	score.outline_modulate = player_label.outline_modulate
	score.name = "Player" + player.player_num
	score.show()

func _on_new_round_timer_timeout():
	select_random_level()	
	new_round()
	
	
func _on_round_start_timer_timeout():
	display_text("Go!", 1.5)
	$Go.play()
	get_tree().call_group("TankDriver", "start_of_round")


func _on_text_duration_timer_timeout():
	display_text("")
