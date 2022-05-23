extends KinematicBody2D

const EnemyDeath = preload("res://src/enemies/EnemyDeath.tscn")
const FlapperShot = preload("res://src/projectiles/FlapperShot.tscn")

enum State { IDLE, ATTACK }

export(int) var SPEED = 60
export(int) var INITIAL_ACCELERATION = 5
export(int) var CHANGE_DIRECTION_ACCELERATION = 5
export(int) var MAX_ACCELERATION = 25
export(int) var speed_boost = 0
export(int) var health = 3

var current_state = State.IDLE
var init = true
var previous_direction = Vector2.LEFT
var direction = Vector2.DOWN
var velocity = Vector2.ZERO
var acceleration = 5

export(Texture) var death_sprite = null

func _physics_process(delta):
	match current_state:
		State.IDLE:
			handle_idle(delta)
		State.ATTACK:
			handle_attack(delta)

func handle_attack(delta):
	if init:
		init = false
		$ProjectileTimer.start()
		AudioManager.play_sfx("BatSpawned")
		acceleration = INITIAL_ACCELERATION
		direction = global_position.direction_to(Globals.PlayerPosition)
		$ChangeDirectionTimer.start()
		$AnimationPlayer.seek(.25)
		$AnimationPlayer.play("flap")
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

func die():
	spawn_death()
	queue_free()

func take_damage():
	health -= 1
	if health <= 0:
		die()
	else:
		SPEED -= 20
		$DamagedPlayer.play("hurt")

func fire_projectile():
	var next_shot = FlapperShot.instance()
	get_parent().add_child(next_shot)
	next_shot.position = position
	next_shot.set_direction(global_position.direction_to(Globals.PlayerPosition))

func spawn_death():
	var next_death = EnemyDeath.instance()
	get_parent().get_parent().find_node("EnemyDeaths").add_child(next_death)
	next_death.texture = death_sprite
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
			die()
		else:
			body.take_damage()

func _on_ProjectileTimer_timeout():
	fire_projectile()
