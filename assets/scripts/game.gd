extends Node

var game_started: bool = false
var game_active: bool = true

var time_since_last_spawn: float = 0.0
var spawn_interval: float = 2.0

enum FoodType {SMALL, MEDIUM, LARGE}

func _ready() -> void:
	new_game()

func _process(delta: float) -> void:
	time_since_last_spawn += delta

	if time_since_last_spawn >= spawn_interval:
		spawn_random_food()
		time_since_last_spawn = 0.0

func spawn_random_food():
	var food = Food.new()

	var food_type = randi() % FoodType.size()
	match food_type:
		FoodType.SMALL:
			food.nutrition_value = 5
			food.scale = Vector2(0.5, 0.5)
		FoodType.MEDIUM:
			food.nutrition_value = 10
			food.scale = Vector2(0.75, 0.75)
		FoodType.LARGE:
			food.nutrition_value = 15
			food.scale = Vector2(1.0, 1.0)
	
	var viewport_rect = get_viewport().get_visible_rect()
	food.position = Vector2(
		randf_range(0, viewport_rect.size.x),
		randf_range(0, viewport_rect.size.y),
	)

	add_child(food)

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

func _on_game_over_menu_restart() -> void:
	new_game()
