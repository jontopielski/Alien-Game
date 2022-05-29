extends KinematicBody2D

const EnemyDeath = preload("res://src/enemies/EnemyDeath.tscn")
const Flapper = preload("res://src/enemies/Flapper.tscn")

export(int) var GRAVITY = 1000
export(int) var TERMINAL_VELOCITY = 150
export(int) var SPEED = 50

var health = 5
var velocity = Vector2.ZERO

func _physics_process(delta):
	velocity.y = min(TERMINAL_VELOCITY, lerp(velocity.y, velocity.y + GRAVITY * delta, 3 * delta))
	move_and_collide(velocity * delta)

func activate(totem_phase):
	if totem_phase == Globals.TotemPhase.SUMMON:
		$AnimationPlayer.play("summon")

func die():
	spawn_death()
	Globals.IsSummonDead = true
	queue_free()

func take_damage():
	health -= 1
	$DamagePlayer.play("damaged")
	if health <= 0:
		spawn_death()
		Globals.IsSummonDead = true
		queue_free()

func summon_enemy():
	get_tree().call_group("level", "summon_flapper")

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
	if anim_name == "summon":
		$AnimationPlayer.play("idle")
