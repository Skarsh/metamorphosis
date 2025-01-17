extends Node

class_name AudioManager

var player_dict = {}
var current_player_music_key: String

func _init():
	var larve_music = preload("res://assets/LarvaMusic2.wav")
	var butterfly_music = preload("res://assets/Metamorphis_2.wav")
	var eat_sound = preload("res://assets/LarvaEatFX.wav")

	var larve_player = AudioStreamPlayer2D.new()
	larve_player.stream = larve_music

	var butterfly_player = AudioStreamPlayer2D.new()
	butterfly_player.stream = butterfly_music

	var eat_player = AudioStreamPlayer2D.new()
	eat_player.stream = eat_sound

	current_player_music_key = "larve"
	player_dict = {"larve": larve_player, "butterfly": butterfly_player, "eat": eat_player}

	for player in player_dict.values():
		add_child(player)

func play(player: String) -> bool:
	if player_dict.has(player):
		if player == "larve" or player == "butterfly":
			current_player_music_key = player
		player_dict[player].play()
		return true
	return false

func stop(player: String) -> bool:
	if player_dict.has(player) and current_player_music_key == player:
		player_dict[player].stop()
		return true
	return false

func swap_music():
	if current_player_music_key == "larve":
		stop("larve")
		play("butterfly")
		current_player_music_key = "butterfly"
	else:
		stop("butterfly")
		play("larve")
		current_player_music_key = "larve"
