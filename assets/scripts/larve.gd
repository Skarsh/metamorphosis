extends Node2D
class_name Larve

@export var animated_sprite: AnimatedSprite2D
var size_factor: float = 3.0
var size_xy_pixels = Vector2(32, 32) * size_factor

var health: int = 100
var movement_speed: int = 300  # Increased for better feel
var rotation_speed: float = 3.0  # Radians per second
var velocity = Vector2.ZERO

func _ready() -> void:
	if !has_node("CollisionArea"):
		var area = Area2D.new()
		area.name = "CollisionArea"
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = size_xy_pixels.x / 2 / size_factor
		shape.shape = circle
		area.add_child(shape)
		add_child(area)
	self.scale = Vector2(self.size_factor, self.size_factor)

func _process(delta: float) -> void:
	if Input.is_action_pressed("move_right"):
		rotate(rotation_speed * delta)
	if Input.is_action_pressed("move_left"):
		rotate(-rotation_speed * delta)
	
	if Input.is_action_pressed("move_forward"):
		var direction = Vector2.UP.rotated(rotation)
		position += direction * movement_speed * delta
		animated_sprite.play("move")
	else:
		# Stop animation when not moving
		animated_sprite.stop()

func eat(nutrition: int) -> void:
	health += nutrition
	size_factor += 0.05
	self.scale = Vector2(size_factor, size_factor)
	print("Ate food! Health: ", health)