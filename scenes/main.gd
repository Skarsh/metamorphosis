extends Node2D

# Game Constants
const COLLISION_RADIUS = 15
const MAX_POSITIONS = 10_000
const NECK_SEGMENTS = 2
const SEGMENT_SPACING = 40
const RECORD_INTERVAL = 0.05
const BASE_SPEED = 200
const BOOST_MULTIPLIER = 1.8
const NORMAL_MULTIPLIER = 1.0
const TURN_RATE = 5.0

var viewport_size: Vector2
var game_started: bool = false
var game_active: bool = true

@onready var snake: Snake
@onready var food = Food.new()
@onready var audio_player = AudioStreamPlayer.new()

class SnakeSegment extends Node2D:
    var sprite: Sprite2D
    var shadow: Sprite2D
    var segment_type: String
    var target_rotation = 0.0
    var collision_area: Area2D
    var spine_line: Line2D  # New line for spine
    
    func _init(type: String, sprite_texture: Texture2D):
        segment_type = type
        
        # Add spine line
        spine_line = Line2D.new()
        spine_line.width = 8.0
        spine_line.default_color = Color(0.4, 0.8, 0.3, 1.0)
        spine_line.z_index = 0  # Same as sprite
        spine_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
        spine_line.end_cap_mode = Line2D.LINE_CAP_ROUND
        add_child(spine_line)
        
        # Add collision area for head only
        if type == "head":
            collision_area = Area2D.new()
            var collision = CollisionShape2D.new()
            var circle_shape = CircleShape2D.new()
            circle_shape.radius = COLLISION_RADIUS  
            collision.shape = circle_shape
            collision_area.add_child(collision)
            add_child(collision_area)
        
        # Shadow setup
        shadow = Sprite2D.new()
        shadow.texture = sprite_texture
        shadow.centered = true
        shadow.modulate = Color(0, 0, 0, 0.3)
        shadow.position = Vector2(4, 4)
        shadow.z_index = -1
        
        if type == "head":
            shadow.scale = Vector2(0.5, 0.5)
        else:
            shadow.scale = Vector2(0.5, 0.5)
            
        add_child(shadow)
        
        # Main sprite
        sprite = Sprite2D.new()
        sprite.texture = sprite_texture
        sprite.centered = true
        
        if type == "head":
            sprite.scale = Vector2(2.0, 2.0)
            
        add_child(sprite)
    
    func update_rotation(target_pos: Vector2, current_pos: Vector2) -> void:
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

# Define Food class
class Food:
    var sprite: Area2D
    var collision: CollisionShape2D
    var sprite_node: Sprite2D
    var position: Vector2
    var viewport_size: Vector2
    
    func _init():
        sprite = Area2D.new()
        sprite_node = Sprite2D.new()
        sprite_node.texture = preload("res://assets/blad/blad2.png")
        sprite_node.scale = Vector2(1.0, 1.0)
        
        # Add collision shape
        collision = CollisionShape2D.new()
        var circle_shape = CircleShape2D.new()
        circle_shape.radius = COLLISION_RADIUS
        collision.shape = circle_shape
        
        sprite.add_child(sprite_node)
        sprite.add_child(collision)
    
    func move(snake_segments: Array, _collision_radius: float) -> void:
        var valid_position = false
        while not valid_position:
            position = Vector2(
                randf_range(50, viewport_size.x - 50),
                randf_range(50, viewport_size.y - 50)
            )
            
            valid_position = true
            for segment in snake_segments:
                # Basic check to avoid spawning directly on snake
                if segment.position.distance_to(position) < 30:
                    valid_position = false
                    break
        
        sprite.position = position

class Snake:
    var segment_positions = []
    var body_segments = []
    var time_since_record = 0
    var speed_multiplier = NORMAL_MULTIPLIER
    var current_direction = Vector2.RIGHT
    var is_growing = false
    var growth_time = 0.0
    var score: int = 0
    var viewport_size: Vector2
    
    var _parent_node: Node  # Reference to parent for adding children
    var _hud: Node  # Reference to HUD for score updates
    
    func _init(parent: Node, viewport: Vector2, hud: Node):
        _parent_node = parent
        viewport_size = viewport
        _hud = hud
        
    func initialize(start_pos: Vector2) -> void:
        # Clear any existing segments
        for segment in body_segments:
            segment.queue_free()
        body_segments.clear()
        segment_positions.clear()
        
        # Reset score
        score = 0
        _hud.get_node("ScoreLabel").text = "SCORE: " + str(score)
        
        # Create initial segments
        var head = SnakeSegment.new("head", preload("res://assets/larve/Larve4Head1.png"))
        var body = SnakeSegment.new("body", preload("res://assets/larve/Larve4Body1.png"))
        var tail = SnakeSegment.new("tail", preload("res://assets/larve/Larve4Butt1.png"))
        
        # Set initial positions with proper spacing
        head.position = start_pos
        body.position = start_pos + Vector2.DOWN * SEGMENT_SPACING
        tail.position = start_pos + Vector2.DOWN * (SEGMENT_SPACING * 2)
        
        # Initialize segment_positions with proper spacing
        segment_positions.push_front(head.position)  # Most recent position first
        segment_positions.push_front(body.position)
        segment_positions.push_front(tail.position)
        
        # Set proper scales
        for segment in [head, body, tail]:
            segment.sprite.scale = Vector2(2.0, 2.0)
            segment.shadow.scale = segment.sprite.scale
            _parent_node.add_child(segment)
            body_segments.append(segment)
        
        # Reset direction
        current_direction = Vector2.UP
        
        # Record initial position for segment movement
        segment_positions.push_front(start_pos)
    
    func handle_input(delta: float) -> void:
        if Input.is_action_pressed("move_right"):
            current_direction = current_direction.rotated(TURN_RATE * delta)
        if Input.is_action_pressed("move_left"):
            current_direction = current_direction.rotated(-TURN_RATE * delta)
        
        speed_multiplier = BOOST_MULTIPLIER if Input.is_action_pressed("left_shift") else NORMAL_MULTIPLIER
    
    func update_position(delta: float) -> void:
        var head = body_segments[0]
        if !head:
            return
            
        if Input.is_action_pressed("move_forward"):
            head.position += current_direction * (BASE_SPEED * speed_multiplier) * delta
            
        head.update_rotation(head.position + current_direction, head.position)
        
        if Input.is_action_pressed("move_forward"):
            time_since_record += delta
            if time_since_record >= RECORD_INTERVAL:
                segment_positions.push_front(head.position)
                time_since_record = 0
                
                if segment_positions.size() > MAX_POSITIONS:
                    segment_positions.resize(MAX_POSITIONS)
    
    func check_collision() -> bool:
        var head = body_segments[0]
        
        # Check for wall collisions
        if head.position.x < 0 or head.position.x > viewport_size.x or \
           head.position.y < 0 or head.position.y > viewport_size.y:
            return true
        
        # Check for self collision
        for i in range(NECK_SEGMENTS + 1, body_segments.size()):
            if head.position.distance_to(body_segments[i].position) < COLLISION_RADIUS:
                return true
                
        return false
    
    func update_spine_lines() -> void:
        for i in range(body_segments.size() - 1):
            var current_segment = body_segments[i]
            var next_segment = body_segments[i + 1]
            
            # Calculate positions in global space
            var start_pos = current_segment.global_position
            var end_pos = next_segment.global_position
            
            # Convert to local space for the line
            var local_start = current_segment.to_local(start_pos)
            var local_end = current_segment.to_local(end_pos)
            
            # Update the spine line
            current_segment.spine_line.clear_points()
            current_segment.spine_line.add_point(local_start)
            current_segment.spine_line.add_point(local_end)
    
    func update_segments(delta: float) -> void:
        for i in range(1, body_segments.size()):
            var segment = body_segments[i]
            var target_idx = i * 2
            
            if target_idx < segment_positions.size():
                var target_pos = segment_positions[target_idx]
                
                if is_growing && i == body_segments.size() - 1:
                    update_growing_segment(segment, i, target_pos, delta)
                else:
                    segment.position = segment.position.lerp(target_pos, 0.2)
                    
                if target_idx + 1 < segment_positions.size():
                    segment.update_rotation(segment_positions[target_idx + 1], target_pos)
        
        # Update spine lines after moving segments
        update_spine_lines()
    
    func update_growing_segment(segment: SnakeSegment, index: int, target_pos: Vector2, delta: float) -> void:
        growth_time += delta * 3
        var growth_factor = min(1.0, growth_time)
        var start_pos = body_segments[index-1].position
        segment.position = start_pos.lerp(target_pos, growth_factor)
        segment.sprite.scale = Vector2(2.0, 2.0) * growth_factor
        segment.shadow.scale = segment.sprite.scale
        
        if growth_factor >= 1.0:
            is_growing = false
            growth_time = 0.0
            score += 1
            _hud.get_node("ScoreLabel").text = "SCORE: " + str(score)
    
    func grow() -> void:
        if is_growing:
            return
            
        # Convert current tail to body segment
        var old_tail = body_segments[-1]
        old_tail.sprite.texture = preload("res://assets/larve/Larve4Body1.png")
        old_tail.segment_type = "body"
        
        # Create new tail
        var new_tail = SnakeSegment.new("tail", preload("res://assets/larve/Larve4Butt1.png"))
        new_tail.position = old_tail.position
        new_tail.sprite.scale = Vector2(2.0, 2.0)
        new_tail.shadow.scale = new_tail.sprite.scale
        
        body_segments.append(new_tail)
        _parent_node.add_child(new_tail)
        
        is_growing = true
        growth_time = 0.0
    
    func reset(start_pos: Vector2) -> void:
        initialize(start_pos)

func _ready() -> void:
    viewport_size = get_viewport_rect().size
    food.viewport_size = viewport_size
    add_child(food.sprite)
    
    snake = Snake.new(self, viewport_size, $Hud)
    
    # Connect food collision signal
    food.sprite.area_entered.connect(_on_food_collision)
    
    audio_player.stream = preload("res://assets/LarvaEatFX.wav")
    audio_player.volume_db = -10
    add_child(audio_player)
    
    new_game()

func _physics_process(delta: float) -> void:
    if !game_active:
        return
    
    snake.handle_input(delta)
    snake.update_position(delta)
    
    if snake.check_collision():
        end_game()
        return
        
    snake.update_segments(delta)

func _on_food_collision(area: Area2D) -> void:
    if area == snake.body_segments[0].collision_area:
        audio_player.play()
        snake.grow()
        food.move(snake.body_segments, COLLISION_RADIUS)

func new_game() -> void:
    get_tree().paused = false
    $GameOverMenu.hide()
    game_active = true
    game_started = false
    
    snake.reset(viewport_size / 2)
    food.move(snake.body_segments, COLLISION_RADIUS)

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