extends Sprite

export(int) var SPEED = 100
export(int) var GRAVITY = 700

var direction = Vector2.UP
var velocity = Vector2.ZERO
var is_falling = false

export(Texture) var boots_death = null

func _ready():
	is_falling = true
	velocity.y = direction.y * 250
	if Globals.HasJetPack:
		texture = boots_death

var spin = 0
func _physics_process(delta):
	if is_falling:
		velocity.y += GRAVITY * delta
		velocity.x = lerp(velocity.x, SPEED * direction.x, 1 * delta)
		position += velocity * delta
		spin = lerp(spin, 10, 5 * delta)
#		rotate(delta * spin)

func _on_Timer_timeout():
	queue_free()
