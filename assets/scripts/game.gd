extends Node

@export var player: Player

var audio_manager: AudioManager
var game_started: bool = false
var game_active: bool = true

var time_since_last_spawn: float = 0.0
var spawn_interval: float = 1.0

var time_since_last_morph: float = 0.0
var morph_duration: float = 10.0

func _ready() -> void:

	audio_manager = AudioManager.new()
	add_child(audio_manager)
	audio_manager.play("larve")
	new_game()

func _process(delta: float) -> void:
	time_since_last_spawn += delta
	time_since_last_morph += delta

	if time_since_last_morph >= morph_duration and player.current_mode == Player.Mode.BUTTERFLY: 
		player.current_mode = player.Mode.LARVE
		player.health = 100
		audio_manager.swap_music()
		player.animated_sprite = player.larve_animated_sprite
		player.butterfly_animated_sprite.hide()
		player.larve_animated_sprite.show()
		player.movement_speed = player.BASE_MOVEMENT_SPEED

	if time_since_last_spawn >= spawn_interval:
		spawn_random_food()
		time_since_last_spawn = 0.0

	if player.health <= 0:
		end_game()
	
	if player.health >= 110 and player.current_mode == Player.Mode.LARVE:
		player.animated_sprite = player.butterfly_animated_sprite
		player.larve_animated_sprite.hide()
		player.butterfly_animated_sprite.show()
		player.current_mode = player.Mode.BUTTERFLY
		player.movement_speed = player.BASE_MOVEMENT_SPEED * 2
		audio_manager.swap_music()
		time_since_last_morph = 0.0
	

func spawn_random_food():
	var food = Food.new()

	var food_type = randi() % Food.FoodType.size()
	match food_type:
		Food.FoodType.SMALL:
			food.nutrition_value = 5
			food.scale = Vector2(0.5, 0.5)
		Food.FoodType.MEDIUM:
			food.nutrition_value = 10
			food.scale = Vector2(0.75, 0.75)
		Food.FoodType.LARGE:
			food.nutrition_value = 15
			food.scale = Vector2(1.0, 1.0)
	
	var viewport_rect = get_viewport().get_visible_rect()
	food.position = Vector2(
		randf_range(0, viewport_rect.size.x),
		randf_range(0, viewport_rect.size.y),
	)

	add_child(food)

func on_food_eaten() -> void:
	audio_manager.play("eat")

func new_game() -> void:
	get_tree().paused = false
	$GameOverMenu.hide()
	game_active = true
	game_started = false

	for i in range(5):
		spawn_random_food()
	
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
