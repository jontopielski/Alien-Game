extends KinematicBody2D

enum State { IDLE, FALL, RISE }

export(int) var SPEED = 50
export(int) var ACCELERATION = 50
export(int) var GRAVITY = 1000
export(int) var TERMINAL_VELOCITY = 150

var current_state = State.IDLE
var init = true

var velocity = Vector2.ZERO
var starting_position = Vector2.ZERO
var is_stopped = false
var can_fall = false

func _physics_process(delta):
	match current_state:
		State.IDLE:
			handle_idle(delta)
		State.RISE:
			handle_rise(delta)
		State.FALL:
			handle_fall(delta)

func handle_idle(delta):
	if init:
		init = false
		can_fall = false
		$CanFallTimer.start()
	if is_player_below() and can_fall:
		change_state(State.FALL)

func handle_rise(delta):
	if init:
		is_stopped = true
		init = false
		velocity.y = 0
		$StopTimer.start()
		get_tree().call_group("level", "screenshake")
	if global_position.y <= starting_position.y:
		global_position.y = starting_position.y
		change_state(State.IDLE)
	if abs(starting_position.y - global_position.y) < 16 and $KillPlayerArea/CollisionShape2D.disabled:
		$KillPlayerArea/CollisionShape2D.set_deferred("disabled", false)
	if !is_stopped:
		velocity.y = min(-35, lerp(velocity.y, velocity.y + -250 * delta, 1 * delta))
		global_position += velocity * delta

func is_player_below():
	return Globals.PlayerPosition.x > global_position.x - 36 and Globals.PlayerPosition.x < global_position.x + 36 and Globals.PlayerPosition.y > global_position.y + 32 and Globals.PlayerPosition.y < global_position.y + (10 * 16)

func handle_fall(delta):
	if init:
		$KillPlayerArea/CollisionShape2D.set_deferred("disabled", true)
		init = false
		velocity.y = 0
	velocity.y = min(TERMINAL_VELOCITY, lerp(velocity.y, velocity.y + GRAVITY * delta, ACCELERATION * delta))
	var collision = move_and_collide(velocity * delta)
	if collision:
		if "TileMap" in collision.collider.name or "Player" in collision.collider.name:
			AudioManager.play_sfx("BigEnemyLanded")
			if "Player" in collision.collider.name:
				get_tree().call_group("player", "die")
			change_state(State.RISE)
		elif collision.collider.has_method("die"):
			collision.collider.die()

func change_state(next_state):
	init = true
	current_state = next_state

func _on_RecordPositionTimer_timeout():
	starting_position = global_position

func _on_StopTimer_timeout():
	is_stopped = false

func _on_CanFallTimer_timeout():
	can_fall = true

func _on_KillPlayerArea_body_entered(body):
	if "Player" in body.name:
		get_tree().call_group("player", "die")
