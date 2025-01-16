extends Node

class_name AudioManager

var players: Array[AudioStreamPlayer2D]
var current_player_idx: int

func _init():
	var larve_music = preload("res://assets/LarvaMusic2.wav")
	var butterfly_music = preload("res://assets/Metamorphis_2.wav")
	var eat_sound = preload("res://assets/LarvaEatFX.wav")

	var larve_player = AudioStreamPlayer2D.new()
	larve_player.stream = larve_music
	players.append(larve_player)

	var butterfly_player = AudioStreamPlayer2D.new()
	butterfly_player.stream = butterfly_music
	players.append(butterfly_player)

	var eat_player = AudioStreamPlayer2D.new()
	eat_player.stream = eat_sound
	players.append(eat_player)

	current_player_idx = 0

	for player in players:
		add_child(player)

func get_current_player() -> int:
	return current_player_idx

func play() -> void:
	players[current_player_idx].play()

func play_eat():
	players[2].play()

func stop() -> void:
	players[current_player_idx].stop()

func swap() -> void:
	if current_player_idx == 0:
		current_player_idx = 1
	else:
		current_player_idx = 0