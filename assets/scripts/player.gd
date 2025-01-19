extends Node2D
class_name Player

@export var larve_animated_sprite: AnimatedSprite2D
@export var butterfly_animated_sprite: AnimatedSprite2D

const BASE_MOVEMENT_SPEED: int = 200
const BASE_HEALTH: int = 100

var animated_sprite: AnimatedSprite2D
var size_factor: float = 1.0

var larve_size_xy_pixels = Vector2(32, 32)
var butterfly_size_xy_pixel = Vector2(64, 64)

var health: int = 100
var movement_speed: int = BASE_MOVEMENT_SPEED 
var rotation_speed: float = 6.0  # Radians per second
var velocity = Vector2.ZERO
var current_mode = Mode

var collision_shape: CollisionShape2D
var larve_capsule_shape: CapsuleShape2D
var butterfly_rect_shape: RectangleShape2D

enum Mode {LARVE, BUTTERFLY}

func _ready() -> void:
	animated_sprite = larve_animated_sprite
	butterfly_animated_sprite.hide()
	current_mode = Mode.LARVE

	if !has_node("CollisionArea"):
		var area = Area2D.new()
		area.name = "CollisionArea"
		collision_shape = CollisionShape2D.new()
		larve_capsule_shape = CapsuleShape2D.new()
		larve_capsule_shape.radius = larve_size_xy_pixels.x / 2 / size_factor
		collision_shape.shape = larve_capsule_shape
		area.add_child(collision_shape)
		add_child(area)

	self.scale = Vector2(self.size_factor, self.size_factor)

func _process(delta: float) -> void:
	if Input.is_action_pressed("move_right") || Input.is_action_pressed("ui_right"):
		rotate(rotation_speed * delta)
	if Input.is_action_pressed("move_left") || Input.is_action_pressed("ui_left"):
		rotate(-rotation_speed * delta)
	
	if Input.is_action_pressed("move_forward") || Input.is_action_pressed("ui_up"):
		var direction = Vector2.UP.rotated(rotation)
		position += direction * movement_speed * 2.0 * delta
		animated_sprite.play("move")
	else:
		var direction = Vector2.UP.rotated(rotation)
		position += direction * movement_speed * delta
		animated_sprite.play("move")


func eat() -> void:
	if current_mode == Mode.LARVE:
		size_factor += 0.05
		self.scale = Vector2(size_factor, size_factor)

func repellant(damage: int) -> void:
	if current_mode == Mode.LARVE:
		size_factor *= 0.80
		self.scale = Vector2(size_factor, size_factor)
		self.health -= damage
	else: 
		self.health -= damage



