#extends Node2D
#
#var head_sprite = preload("res://assets/head.png")
#var body_sprite = preload("res://assets/body.png")
#var tail_sprite = preload("res://assets/tail.png")
#
#var segment_positions = []  # Queue of historical positions
#var body_segments = []     # Array of actual body nodes
#var record_interval = 0.05  # Reduced for smoother tracking
#var time_since_record = 0
#var speed = 200
#var segment_spacing = 40  # Fixed spacing between segments
#
#class SnakeSegment extends Node2D:
#    var sprite: Sprite2D
#    var segment_type: String
#    var target_rotation = 0.0
#    
#    func _init(type: String, sprite_texture: Texture2D):
#        segment_type = type
#        sprite = Sprite2D.new()
#        sprite.texture = sprite_texture
#        sprite.centered = true
#        # Make sprites visible with a good size
#        sprite.scale = Vector2(0.5, 0.5)  # Adjust based on your sprite size
#        add_child(sprite)
#    
#    func update_rotation(target_pos: Vector2, current_pos: Vector2):
#        if target_pos.distance_to(current_pos) > 1:  # Only rotate if moving
#            var direction = (target_pos - current_pos).normalized()
#            target_rotation = atan2(direction.y, direction.x)
#            target_rotation = rad_to_deg(target_rotation) + 90
#        
#        sprite.rotation_degrees = lerp_angle(
#            deg_to_rad(sprite.rotation_degrees),
#            deg_to_rad(target_rotation),
#            0.2
#        )
#
#func _ready():
#    # Create initial head segment
#    var head = SnakeSegment.new("head", head_sprite)
#    add_child(head)
#    body_segments.append(head)
#    # Add initial body and tail
#    grow()
#    grow()
#
#func _physics_process(delta):
#    var input = Vector2(
#        Input.get_axis("ui_left", "ui_right"),
#        Input.get_axis("ui_up", "ui_down")
#    )
#    
#    if input.length() > 0:
#        # Move head
#        var head = body_segments[0]
#        head.position += input.normalized() * speed * delta
#        head.update_rotation(head.position + input.normalized(), head.position)
#        
#        # Record head position more frequently
#        time_since_record += delta
#        if time_since_record >= record_interval:
#            segment_positions.push_front(head.position)
#            time_since_record = 0
#            
#            # Keep a reasonable history
#            while segment_positions.size() > body_segments.size() * 4:
#                segment_positions.pop_back()
#    
#    # Update body segments
#    for i in range(1, body_segments.size()):
#        var segment = body_segments[i]
#        var target_pos: Vector2
#        
#        # Calculate target position based on previous segment
#        var prev_segment = body_segments[i-1]
#        var direction = (prev_segment.position - segment.position).normalized()
#        target_pos = prev_segment.position - direction * segment_spacing
#        
#        # Smooth movement
#        segment.position = segment.position.lerp(target_pos, 0.2)
#        segment.update_rotation(target_pos, segment.position)
#
#func grow():
#    var new_segment: SnakeSegment
#    
#    if body_segments.size() == 0:
#        new_segment = SnakeSegment.new("head", head_sprite)
#    elif body_segments.size() == 1:
#        new_segment = SnakeSegment.new("body", body_sprite)
#    else:
#        # Convert previous tail to body if it exists
#        if body_segments[-1].segment_type == "tail":
#            body_segments[-1].sprite.texture = body_sprite
#            body_segments[-1].segment_type = "body"
#        new_segment = SnakeSegment.new("tail", tail_sprite)
#    
#    # Position the new segment
#    if body_segments.size() > 0:
#        var last_segment = body_segments[-1]
#        new_segment.position = last_segment.position
#        if body_segments.size() > 1:
#            var direction = (body_segments[-2].position - last_segment.position).normalized()
#            new_segment.position = last_segment.position - direction * segment_spacing
#    
#    body_segments.append(new_segment)
#    add_child(new_segment)
#
#func _input(event):
#    if event.is_action_pressed("ui_accept"):  # Space bar
#        grow()

extends Node2D

var head_sprite = preload("res://assets/head.png")
var body_sprite = preload("res://assets/body.png")
var tail_sprite = preload("res://assets/tail.png")

var segment_positions = []
var body_segments = []
var record_interval = 0.05
var time_since_record = 0
var base_speed = 200  # Rename existing speed var or create new one
var speed_multiplier = 1.0
var boost_multiplier = 1.8  # How much faster when boosting

var segment_spacing = 40
var turn_speed = 5.0
var last_direction = Vector2.RIGHT
var is_growing = false
var growth_time = 0.0
var max_positions = 10_000
var neck_segments = 5
var collision_radius = 15
var game_active = true

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
        shadow.scale = Vector2(0.5, 0.5)
        shadow.modulate = Color(0, 0, 0, 0.3)
        shadow.position = Vector2(4, 4)
        shadow.z_index = -1
        add_child(shadow)
        
        # Main sprite
        sprite = Sprite2D.new()
        sprite.texture = sprite_texture
        sprite.centered = true
        sprite.scale = Vector2(0.5, 0.5)
        add_child(sprite)
    
    func update_rotation(target_pos: Vector2, current_pos: Vector2):
        if target_pos.distance_to(current_pos) > 1:
            var direction = (target_pos - current_pos).normalized()
            var angle = atan2(direction.y, direction.x)
            target_rotation = rad_to_deg(angle) + 90
            sprite.rotation_degrees = target_rotation
            shadow.rotation_degrees = target_rotation

func _ready():
    var head = SnakeSegment.new("head", head_sprite)
    add_child(head)
    body_segments.append(head)
    grow()
    grow()

func check_collision() -> bool:
    var head = body_segments[0]
    
    for i in range(neck_segments + 1, body_segments.size()):
        var segment = body_segments[i]
        var distance = head.position.distance_to(segment.position)
        
        if distance < collision_radius:
            return true
            
    return false

# Add these variables at the top with the others
var current_direction = Vector2.RIGHT  # Track actual movement direction
enum TurnBehavior { IGNORE, CIRCULAR }
var turn_behavior = TurnBehavior.CIRCULAR  # Change this to try different behaviors

func _physics_process(delta):
    if !game_active:
        return
        
    var input = Vector2(
        Input.get_axis("ui_left", "ui_right"),
        Input.get_axis("ui_up", "ui_down")
    )
    
    # Update speed multiplier based on shift key
    speed_multiplier = 1.8 if Input.is_action_pressed("left_shift") else 1.0
    
    if input.length() > 0:
        var new_direction = input.normalized()
        
        # Check if trying to move in opposite direction
        if new_direction.dot(current_direction) < -0.1:
            match turn_behavior:
                TurnBehavior.IGNORE:
                    new_direction = current_direction
                
                TurnBehavior.CIRCULAR:
                    var cross_z = current_direction.x * new_direction.y - current_direction.y * new_direction.x
                    if cross_z > 0:
                        new_direction = Vector2(-current_direction.y, current_direction.x)
                    else:
                        new_direction = Vector2(current_direction.y, -current_direction.x)
        
        last_direction = last_direction.lerp(new_direction, turn_speed * delta)
        current_direction = last_direction.normalized()
        
        var head = body_segments[0]
        # Apply speed multiplier to movement
        head.position += last_direction * (base_speed * speed_multiplier) * delta
        head.update_rotation(head.position + last_direction, head.position)
        
        if check_collision():
            game_active = false
            print("Snake collided! Game Over!")
            return
        
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
                segment.sprite.scale = Vector2(0.5, 0.5) * growth_factor
                segment.shadow.scale = segment.sprite.scale
                
                if growth_factor >= 1.0:
                    is_growing = false
                    growth_time = 0.0
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
        new_segment.sprite.scale = Vector2(0.05, 0.05)
        new_segment.shadow.scale = new_segment.sprite.scale
    
    body_segments.append(new_segment)
    add_child(new_segment)
    
    is_growing = true
    growth_time = 0.0

func _input(event):
    if event.is_action_pressed("ui_accept"):  # Space to grow
        grow()