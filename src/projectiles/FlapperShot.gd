extends Area2D

export(int) var SPEED = 125
export(float) var ACCELERATION = 2

export(Color) var COLOR_ONE = Color.white
export(Color) var COLOR_TWO = Color.black

var current_speed = 0
var current_scale = Vector2.ZERO
var direction = Vector2.ZERO

func set_direction(dir):
	direction = dir

func _physics_process(delta):
	current_scale = lerp(current_scale, Vector2(1, 1), 1 * delta)
	current_speed = lerp(current_speed, SPEED, ACCELERATION * delta)
	if direction != Vector2.ZERO:
		position += direction * current_speed * delta

#func _draw():
#	draw_circle(Vector2.ZERO, 8, COLOR_ONE)
#	draw_circle(Vector2.ZERO, 6, COLOR_TWO)

func swap_colors():
	var temp_color = COLOR_TWO
	COLOR_TWO = COLOR_ONE
	COLOR_ONE = temp_color
	update()

func _on_FlapperShot_body_entered(body):
	if "TileMap" in body.name:
		get_tree().call_group("level", "spawn_white_circle", global_position)
		queue_free()
	elif "Player" in body.name:
		body.take_damage()
