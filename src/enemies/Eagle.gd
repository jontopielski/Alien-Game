extends KinematicBody2D

const EnemyDeath = preload("res://src/enemies/EnemyDeath.tscn")

enum State { IDLE, ATTACK }

export(int) var SPEED = 60
export(int) var INITIAL_ACCELERATION = 5
export(int) var CHANGE_DIRECTION_ACCELERATION = 5
export(int) var MAX_ACCELERATION = 25
export(int) var speed_boost = 0

var current_state = State.IDLE
var init = true
var previous_direction = Vector2.LEFT
var direction = Vector2.DOWN
var velocity = Vector2.ZERO
var acceleration = 5
var health = 5

export(Texture) var death_sprite = null

func die():
	spawn_death()
	Globals.IsEagleDead = true
	queue_free()

func _physics_process(delta):
	match current_state:
		State.IDLE:
			handle_idle(delta)
		State.ATTACK:
			handle_attack(delta)

func handle_attack(delta):
	if init:
		init = false
		AudioManager.play_sfx("BatSpawned")
		acceleration = INITIAL_ACCELERATION
		direction = global_position.direction_to(Globals.PlayerPosition)
		$ChangeDirectionTimer.start()
		$AnimationPlayer.seek(.25)
		$AnimationPlayer.play("flap")
	if Globals.PlayerPosition.x > global_position.x:
		$Sprite.flip_h = true
	else:
		$Sprite.flip_h = false
	acceleration = lerp(acceleration, MAX_ACCELERATION, 1 * delta)
	velocity = lerp(velocity, (SPEED + speed_boost) * direction, acceleration * delta)
	move_and_slide(velocity, Vector2.UP)

func handle_idle(delta):
	if init:
		init = false
		$AnimationPlayer.play("idle")

func _on_ScanArea_body_entered(body):
	if "Player" in body.name and current_state == State.IDLE:
		change_state(State.ATTACK)



func take_damage():
	print(health)
	health -= 1
	if health <= 0:
		print("Dead!")
		die()
	else:
		$DamagedPlayer.play("hurt_flash")

func spawn_death():
	var next_death = EnemyDeath.instance()
	get_parent().get_parent().find_node("EnemyDeaths").add_child(next_death)
	next_death.texture = $Sprite.texture
	next_death.hframes = $Sprite.hframes
	next_death.position = position

func change_state(next_state):
	init = true
	current_state = next_state

func _on_ChangeDirectionTimer_timeout():
	previous_direction = direction
	direction = global_position.direction_to(Globals.PlayerPosition)
	if previous_direction.x > 0 and direction.x < 0:
		acceleration = CHANGE_DIRECTION_ACCELERATION
	if previous_direction.x < 0 and direction.x > 0:
		acceleration = CHANGE_DIRECTION_ACCELERATION

func _on_HurtArea_body_entered(body):
	if "Player" in body.name:
		if position.direction_to(body.position).y < -.75:
			body.tiny_boost()
			take_damage()
		else:
			body.take_damage()
