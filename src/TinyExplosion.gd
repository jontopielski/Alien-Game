extends Node2D

var color = Color("#212123")
var radius = 10

func _ready():
	yield(get_tree().create_timer(.05), "timeout")
	color = Color("#d7d5c5")
	yield(get_tree().create_timer(.05), "timeout")
	queue_free()

func _physics_process(delta):
	update()
	radius = lerp(radius, 16, 30 * delta)

func _draw():
	draw_circle(Vector2.ZERO, radius, color)
