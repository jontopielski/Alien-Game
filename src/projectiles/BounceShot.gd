extends KinematicBody2D

const FireballShadow = preload("res://src/projectiles/FireballShadow.tscn")

enum State { JUMP, FALL }

var current_state = State.JUMP

export(int) var SPEED = 50
export(int) var ACCELERATION = 20
export(int) var GRAVITY = 500
export(int) var JUMP_VELOCITY = -150
export(int) var TERMINAL_VELOCITY = 150

var init = false
var direction = Vector2.LEFT
var velocity = Vector2.ZERO

func _physics_process(delta):
	match current_state:
		State.JUMP:
			handle_jump(delta)
		State.FALL:
			handle_fall(delta)

func handle_jump(delta):
	if init:
		init = false
		velocity.y = JUMP_VELOCITY
	if velocity.y >= 0:
		change_state(State.FALL)
	velocity.x = lerp(velocity.x, direction.x * SPEED, ACCELERATION * delta)
	velocity.y = min(TERMINAL_VELOCITY, lerp(velocity.y, velocity.y + GRAVITY * delta, ACCELERATION * delta))
	if abs(move_and_slide(velocity, Vector2.UP).x) < .5 and $LowVelocityTimer.is_stopped():
		$LowVelocityTimer.start()

func spawn_shadow():
	var next_shadow = FireballShadow.instance()
	get_parent().get_parent().find_node("Shadows").add_child(next_shadow)
	next_shadow.position = position + Vector2(0, 0)
	var next_frame = 0 if $Sprite.frame + 1 == 16 else $Sprite.frame + 1
	next_shadow.set_frame($Sprite.frame)
	next_shadow.set_playback_speed(1.5)

func handle_fall(delta):
	if init:
		init = false
	velocity.x = lerp(velocity.x, direction.x * SPEED, ACCELERATION * delta)
	velocity.y = min(TERMINAL_VELOCITY, lerp(velocity.y, velocity.y + GRAVITY * delta, ACCELERATION * delta))
	if abs(move_and_slide(velocity, Vector2.UP).x) < .5 and $LowVelocityTimer.is_stopped():
		$LowVelocityTimer.start()

func change_state(next_state):
	init = true
	current_state = next_state

func _on_Area2D_body_entered(body):
	if "Tile" in body.name:
		change_state(State.JUMP)
	if "Player" in body.name:
		body.take_damage()
		queue_free()

func _on_ShadowTimer_timeout():
	spawn_shadow()

func _on_Area2D_area_entered(area):
	if "Player" in area.name:
		area.get_parent().take_damage()
		queue_free()

func _on_LowVelocityTimer_timeout():
	queue_free()
