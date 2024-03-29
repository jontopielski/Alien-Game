extends Sprite

var speed = 20

onready var direction = Vector2.UP

var bounds = Rect2(Vector2.ZERO, Vector2(320, 240))
var check_bounds = false
var follow_player = false
onready var rotation_speed = rand_range(0.75, 1.25)

func _ready():
	randomize()
	direction = direction.rotated(deg2rad(rand_range(-90, 90)))

func set_direction(dir):
	direction = dir

func _physics_process(delta):
	position += direction * speed * delta
	rotate(delta * rotation_speed)
	if check_bounds:
		if position.x < bounds.position.x or position.x > bounds.position.x + bounds.size.x:
			queue_free()
		if position.y < bounds.position.y or position.y > bounds.position.y + bounds.size.y:
			queue_free()
	if follow_player:
		direction = global_position.direction_to(Globals.PlayerPosition)

func _on_Timer_timeout():
	check_bounds = true
