extends Node2D

var radius = 14
var color = Color.black
var start_rad = 0
var end_rad = 10

func _ready():
	$Tween.interpolate_property(self, "radius", start_rad, end_rad, .1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()

func _process(delta):
	update()

func _draw():
	draw_circle(Vector2.ZERO, radius, color)

func _on_Tween_tween_completed(object, key):
	queue_free()

func _on_Tween_tween_step(object, key, elapsed, value):
	if value > start_rad + 2:
		color = Color.white

func _on_Area2D_body_entered(body):
	pass
