extends Area2D
class_name Food

enum FoodType {SMALL, MEDIUM, LARGE}

var nutrition_value: int = 10
var size_xy_pixels: Vector2 = Vector2(16, 16)
var size_factor: float = 1.0

func _ready() -> void:
	self.scale = Vector2(size_factor, size_factor)
	var shape = CircleShape2D.new()
	shape.radius = size_xy_pixels.x / 2 / size_factor
	var collision = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var sprite = Sprite2D.new()
	var texture = preload("res://assets/blad/blad2.png")
	sprite.texture = texture
	add_child(sprite)
	sprite.modulate = Color.from_hsv(
		randf_range(0.0, 1.0),
		0.8,
		1.0
	)
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() is Player:
		var game = get_parent()
		if game.has_method("on_food_eaten"):
			game.on_food_eaten()
		var larve = area.get_parent()
		larve.eat(nutrition_value)
		queue_free()
