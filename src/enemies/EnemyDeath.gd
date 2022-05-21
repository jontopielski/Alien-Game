extends Sprite

const EnemyExplosion = preload("res://src/effects/EnemyExplosion.tscn")

export(int) var SPEED = 100
export(int) var GRAVITY = 500

var direction = Vector2.UP
var velocity = Vector2.ZERO

func _ready():
	randomize()
	if randi() % 2 == 0:
		direction = Vector2(-1, -1).normalized().rotated(deg2rad(rand_range(-25, 25)))
	else:
		direction = Vector2(1, -1).normalized().rotated(deg2rad(rand_range(-25, 25)))
	velocity.y = direction.y * 100

func spawn_explosion():
	var next_explosion = EnemyExplosion.instance()
	get_parent().add_child(next_explosion)
	next_explosion.position = position

func _physics_process(delta):
	velocity.y += GRAVITY * delta
	velocity.x = lerp(velocity.x, SPEED * direction.x, 1 * delta)
	position += velocity * delta

func _on_Timer_timeout():
	queue_free()
