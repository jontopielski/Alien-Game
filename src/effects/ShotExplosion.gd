extends Sprite

export(Color) var color = Color.black

var stop_drawing = false
var radius = 8
var arc_radius = 0
var projectile_spawn_count = 0

func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()

func _ready():
	if projectile_spawn_count == 4:
		color = Color.black
	elif projectile_spawn_count == 2:
		color = Color.white
	else:
		stop_drawing = true

func _draw():
	if !stop_drawing:
		draw_circle(Vector2.ZERO, radius, color)
#		draw_arc(Vector2.ZERO, arc_radius, 0, PI * 2, 32, color)

func _process(delta):
	arc_radius = lerp(arc_radius, 32, 10 * delta)
	radius = lerp(radius, 16, 15 * delta)
	update()

func _on_DrawStopTimer_timeout():
	stop_drawing = true
	update()
