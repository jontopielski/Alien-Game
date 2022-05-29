extends KinematicBody2D

const EnemyDeath = preload("res://src/enemies/EnemyDeath.tscn")
const Fireball = preload("res://src/projectiles/BounceShot.tscn")
const FlapperShot = preload("res://src/projectiles/FlapperShot.tscn")

export(int) var GRAVITY = 1000
export(int) var TERMINAL_VELOCITY = 150
export(int) var SPEED = 50

var health = 5
var velocity = Vector2.ZERO

func _physics_process(delta):
	velocity.y = min(TERMINAL_VELOCITY, lerp(velocity.y, velocity.y + GRAVITY * delta, 3 * delta))
	move_and_collide(velocity * delta)

func activate(totem_phase):
	if totem_phase == Globals.TotemPhase.SHOOT:
		$AnimationPlayer.play("shoot")
		AudioManager.play_sfx("TotemFireball")

func die():
	spawn_death()
	Globals.IsShootDead = true
	queue_free()

func shoot_fireballs():
	if Globals.BossRounds % 2 == 1:
		shoot_flapper_shot()
	else:
		shoot_fireball(Vector2.RIGHT)
		shoot_fireball(Vector2.LEFT)

func shoot_flapper_shot():
	var next_shot = FlapperShot.instance()
	get_parent().add_child(next_shot)
	next_shot.position = position
	next_shot.set_direction(global_position.direction_to(Globals.PlayerPosition))

func shoot_fireball(dir):
	var next_fireball = Fireball.instance()
	get_parent().add_child(next_fireball)
	next_fireball.direction = dir
	next_fireball.position = global_position + (dir * 12)

func take_damage():
	health -= 1
	$DamagePlayer.play("damaged")
	if health <= 0:
		spawn_death()
		Globals.IsShootDead = true
		queue_free()

func spawn_death():
	var next_death = EnemyDeath.instance()
	get_parent().get_parent().find_node("EnemyDeaths").add_child(next_death)
	next_death.texture = $Sprite.texture
	next_death.hframes = $Sprite.hframes
	next_death.position = position

func _on_Area2D_body_entered(body):
	pass
#	if "Player" in body.name:
#		body.take_damage()

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "shoot":
		$AnimationPlayer.play("idle")
