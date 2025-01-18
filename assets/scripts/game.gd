extends Node

@export var hud: Node
@export var player: Player

var max_repellants = 5
var repellants: Array[Repellant] = []

var audio_manager: AudioManager
var game_started: bool = false
var game_active: bool = true
var game_score: int = 0

var time_since_last_food_spawn: float = 0.0
var food_spawn_interval: float = 1.0

var time_since_last_repellant_spawn: float = 0.0
var repellant_spawn_interval: float = 3.0

var time_since_last_morph: float = 0.0
var morph_duration: float = 10.0

func _ready() -> void:

	repellants.resize(max_repellants)

	audio_manager = AudioManager.new()
	add_child(audio_manager)
	audio_manager.play("larve")
	new_game()

func _process(delta: float) -> void:

	if player.health <= 0:
		end_game()

	time_since_last_food_spawn += delta
	time_since_last_repellant_spawn += delta

	time_since_last_morph += delta

	if time_since_last_food_spawn >= food_spawn_interval:
		spawn_random_food()
		time_since_last_food_spawn = 0.0

	if time_since_last_repellant_spawn >= repellant_spawn_interval:
		spawn_random_repellant()
		time_since_last_repellant_spawn = 0.0
	
	# Morph to butterfly
	if player.size_factor >= 3.5 and player.current_mode == Player.Mode.LARVE:
		player.animated_sprite = player.butterfly_animated_sprite
		player.larve_animated_sprite.hide()
		player.butterfly_animated_sprite.show()
		player.current_mode = player.Mode.BUTTERFLY
		audio_manager.swap_music()
		time_since_last_morph = 0.0
		player.size_factor = 1.0
	
	print("player.size_factor: ", player.size_factor)
		

func spawn_random_food():
	var food = Food.new()
	
	var viewport_rect = get_viewport().get_visible_rect()
	food.position = Vector2(
		randf_range(0, viewport_rect.size.x),
		randf_range(0, viewport_rect.size.y),
	)

	add_child(food)

func spawn_random_repellant():
	var spawned = false

	for i in range(max_repellants):
		var repellant = Repellant.new()
		if repellants[i] == null:
			spawned = true
			repellants[i] = repellant	
			var viewport_rect = get_viewport().get_visible_rect()
			repellant.position = Vector2(
				randf_range(0, viewport_rect.size.x),
				randf_range(0, viewport_rect.size.y),
			)
			add_child(repellant)

	if !spawned:
		var repellant = Repellant.new()
		var rand_idx = randi_range(0, max_repellants - 1)

		remove_child(repellants[rand_idx])

		repellants[rand_idx] = repellant	

		var viewport_rect = get_viewport().get_visible_rect()
		repellant.position = Vector2(
			randf_range(0, viewport_rect.size.x),
			randf_range(0, viewport_rect.size.y),
		)

		add_child(repellant)

func on_food_eaten(nutrition_value: int) -> void:
	game_score += nutrition_value
	hud.get_node("ScoreLabel").text = "SCORE: " + str(game_score)
	hud.get_node("HealthLabel").text = "HEALTH: " + str(player.health)
	audio_manager.play("eat")

func on_repellant() -> void:
	hud.get_node("HealthLabel").text = "HEALTH: " + str(player.health)
	audio_manager.play("eat")

func new_game() -> void:
	get_tree().paused = false
	$GameOverMenu.hide()
	game_active = true
	game_started = false
	hud.get_node("HealthLabel").text = "HEALTH: " + str(player.health)

	for i in range(10):
		spawn_random_food()
	for i in range(2):
		spawn_random_repellant()
	
func start_game() -> void:
	game_started = true
	game_active = true

func end_game() -> void:
	game_active = false
	game_started = false
	$GameOverMenu.show()
	get_tree().paused = true

func won_game() -> void:
	game_active = false
	game_started = false
	$GameWonMenu.show()
	get_tree().paused = true

func _on_game_over_menu_restart() -> void:
	new_game()

func _on_game_won_menu_restart() -> void:
	new_game()
