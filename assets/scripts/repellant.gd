extends Area2D

class_name Repellant

var damage: int = 10
var size_xy_pixels: Vector2 = Vector2(16, 16)
var size_factor: float = 1.0

func _ready() -> void:
	var shape = CircleShape2D.new()
	shape.radius = size_xy_pixels.x / 2 / size_factor
	var collision = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var sprite = Sprite2D.new()
	var texture = preload("res://assets/insect_repellant/InsectRepellant1.png")
	sprite.texture = texture
	add_child(sprite)
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() is Player:
		print("colliding with repellant")
		var game = get_parent()
		if game.has_method("on_repellant"):
			game.on_repellant()
		var larve = area.get_parent()
		larve.repellant(damage)
		queue_free()
