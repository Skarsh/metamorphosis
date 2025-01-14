extends Node2D

var head_sprite = preload("res://assets/Larve4Head1.png")
var body_sprite = preload("res://assets/Larve4Body1.png")
var tail_sprite = preload("res://assets/Larve4Butt1.png")

var segment_positions = []
var body_segments = []
var record_interval = 0.05
var time_since_record = 0
var base_speed = 200
var speed_multiplier = 1.0
var boost_multiplier = 1.8

var segment_spacing = 40
var turn_speed = 5.0
var last_direction = Vector2.RIGHT
var is_growing = false
var growth_time = 0.0
var max_positions = 10_000
var neck_segments = 5
var collision_radius = 15
var game_active = true

var score: int
var game_started: bool = false
var food_position: Vector2
var viewport_size: Vector2
var food_sprite: Sprite2D

class SnakeSegment extends Node2D:
	var sprite: Sprite2D
	var shadow: Sprite2D
	var segment_type: String
	var target_rotation = 0.0
	
	func _init(type: String, sprite_texture: Texture2D):
		segment_type = type
		
		# Shadow setup
		shadow = Sprite2D.new()
		shadow.texture = sprite_texture
		shadow.centered = true
		shadow.modulate = Color(0, 0, 0, 0.3)
		shadow.position = Vector2(4, 4)
		shadow.z_index = -1
		
		# Set scale based on segment type
		if type == "head":
			shadow.scale = Vector2(2.0, 2.0)
		else:
			shadow.scale = Vector2(0.5, 0.5)
			
		add_child(shadow)
		
		# Main sprite
		sprite = Sprite2D.new()
		sprite.texture = sprite_texture
		sprite.centered = true
		
		# Set scale based on segment type
		if type == "head":
			sprite.scale = Vector2(2.0, 2.0)
			
		add_child(sprite)
	
	func update_rotation(target_pos: Vector2, current_pos: Vector2):
		var direction = (target_pos - current_pos).normalized()
		var angle = atan2(direction.y, direction.x)
		
		match segment_type:
			"head":
				target_rotation = rad_to_deg(angle) + 90
			"body":
				target_rotation = rad_to_deg(angle) + 90
			"tail":
				target_rotation = rad_to_deg(angle) - 90
		
		sprite.rotation_degrees = target_rotation
		shadow.rotation_degrees = target_rotation

func _ready():
	viewport_size = get_viewport_rect().size
	# Set up food sprite
	food_sprite = Sprite2D.new()
	food_sprite.texture = preload("res://assets/apple.png")
	food_sprite.scale = Vector2(0.5, 0.5)
	add_child(food_sprite)
	new_game()

func check_collision() -> bool:
	var head = body_segments[0]
	
	# Check for wall collisions
	if head.position.x < 0 or head.position.x > viewport_size.x or \
	   head.position.y < 0 or head.position.y > viewport_size.y:
		return true
	
	# Check for self collision
	for i in range(neck_segments + 1, body_segments.size()):
		var segment = body_segments[i]
		var distance = head.position.distance_to(segment.position)
		
		if distance < collision_radius:
			return true
			
	return false

func move_food():
	var valid_position = false
	while not valid_position:
		# Generate random position within viewport
		food_position = Vector2(
			randf_range(50, viewport_size.x - 50),
			randf_range(50, viewport_size.y - 50)
		)
		
		# Check if position is valid (not too close to snake)
		valid_position = true
		for segment in body_segments:
			if segment.position.distance_to(food_position) < collision_radius * 2:
				valid_position = false
				break
	
	food_sprite.position = food_position

func check_food_collision():
	if body_segments.size() > 0:
		var head = body_segments[0]
		if head.position.distance_to(food_position) < collision_radius:
			grow()
			move_food()

var current_direction = Vector2.RIGHT
enum TurnBehavior { IGNORE, CIRCULAR }
var turn_behavior = TurnBehavior.CIRCULAR

func _physics_process(delta):
	if !game_active:
		return
		
	# Handle turning
	var turn_rate = 2.5  # Adjust this value to change how sharp the snake can turn
	
	# Apply turning based on input
	if Input.is_action_pressed("move_right"):  # D key
		# Rotate current_direction clockwise
		var angle = turn_rate * delta
		current_direction = current_direction.rotated(angle)
	if Input.is_action_pressed("move_left"):  # A key
		# Rotate current_direction counter-clockwise
		var angle = -turn_rate * delta
		current_direction = current_direction.rotated(angle)
	
	# Start game on first forward input
	if !game_started and Input.is_action_pressed("move_forward"):
		start_game()
	
	speed_multiplier = 1.8 if Input.is_action_pressed("left_shift") else 1.0
	
	var head = body_segments[0]
	if head:
		# Only move when pressing forward
		if Input.is_action_pressed("move_forward"):
			head.position += current_direction * (base_speed * speed_multiplier) * delta
			
		# Always update rotation to show direction
		head.update_rotation(head.position + current_direction, head.position)
		
		if check_collision():
			end_game()
			return
			
		check_food_collision()
		
		# Only record positions when moving
		if Input.is_action_pressed("move_forward"):
			time_since_record += delta
			if time_since_record >= record_interval:
				segment_positions.push_front(head.position)
				time_since_record = 0
				
				if segment_positions.size() > max_positions:
					segment_positions.resize(max_positions)
	
	# Update body segments
	for i in range(1, body_segments.size()):
		var segment = body_segments[i]
		var target_idx = i * 2
		
		if target_idx < segment_positions.size():
			var target_pos = segment_positions[target_idx]
			
			if is_growing && i == body_segments.size() - 1:
				growth_time += delta * 3
				var growth_factor = min(1.0, growth_time)
				var start_pos = body_segments[i-1].position
				segment.position = start_pos.lerp(target_pos, growth_factor)
				segment.sprite.scale = Vector2(2.0, 2.0) * growth_factor
				segment.shadow.scale = segment.sprite.scale
				
				if growth_factor >= 1.0:
					is_growing = false
					growth_time = 0.0
					score += 1
					$Hud.get_node("ScoreLabel").text = "SCORE: " + str(score)
			else:
				segment.position = segment.position.lerp(target_pos, 0.2)
				
			if target_idx + 1 < segment_positions.size():
				segment.update_rotation(segment_positions[target_idx + 1], target_pos)

func grow():
	if is_growing:
		return
		
	var new_segment: SnakeSegment
	
	if body_segments.size() == 0:
		new_segment = SnakeSegment.new("head", head_sprite)
	elif body_segments.size() == 1:
		new_segment = SnakeSegment.new("body", body_sprite)
	else:
		if body_segments[-1].segment_type == "tail":
			body_segments[-1].sprite.texture = body_sprite
			body_segments[-1].segment_type = "body"
		new_segment = SnakeSegment.new("tail", tail_sprite)
	
	if body_segments.size() > 0:
		new_segment.position = body_segments[-1].position
		new_segment.sprite.scale = Vector2(2.0, 2.0)
		new_segment.shadow.scale = new_segment.sprite.scale
	
	body_segments.append(new_segment)
	add_child(new_segment)
	
	is_growing = true
	growth_time = 0.0

func _input(event):
	if event.is_action_pressed("ui_accept") and game_active:  # Space to grow
		grow()

func new_game():
	# Reset game state
	get_tree().paused = false
	$GameOverMenu.hide()
	game_active = true
	game_started = false
	score = 0
	$Hud.get_node("ScoreLabel").text = "SCORE: " + str(score)
	
	# Clear existing segments
	for segment in body_segments:
		segment.queue_free()
	body_segments.clear()
	segment_positions.clear()
	
	# Create initial snake
	var head = SnakeSegment.new("head", head_sprite)
	add_child(head)
	body_segments.append(head)
	
	# Spawn initial food
	move_food()
	
	# Reset position and direction (starting facing upward)
	head.position = Vector2(get_viewport_rect().size / 2)
	current_direction = Vector2.UP
	last_direction = Vector2.UP
	
	# Add initial body segments
	grow()
	grow()

func start_game():
	game_started = true
	game_active = true

func end_game():
	game_active = false
	game_started = false
	$GameOverMenu.show()
	get_tree().paused = true

func _on_game_over_menu_restart() -> void:
	new_game()