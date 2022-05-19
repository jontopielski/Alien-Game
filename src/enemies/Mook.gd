extends KinematicBody2D

const EnemyDeath = preload("res://src/enemies/EnemyDeath.tscn")

export(int) var SPEED = 60
export(int) var ACCELERATION = 15
export(int) var GRAVITY = 25
export(int) var TERMINAL_VELOCITY = 100
export(bool) var is_spiked = false
export(Texture) var spiked_texture = null

var direction = Vector2.LEFT
var velocity = Vector2.ZERO
var is_stunned = false

func _ready():
	$AnimationPlayer.play("walk")
	if is_spiked:
		$Sprite.texture = spiked_texture

func _physics_process(delta):
	if is_stunned:
		velocity.x = 0
		velocity.y = min(TERMINAL_VELOCITY, velocity.y + GRAVITY)
		move_and_slide(velocity, Vector2.UP)
		return
	velocity.x = lerp(velocity.x, direction.x * SPEED * 1.1, ACCELERATION * delta)
	velocity.y = min(TERMINAL_VELOCITY, velocity.y + GRAVITY)
	move_and_slide(velocity, Vector2.UP)
	if is_on_wall() and $TurnTimer.is_stopped():
		velocity.y = -150
		$TurnTimer.start()
		direction = direction.rotated(PI).round()
		if direction.x < 0:
			$Sprite.flip_h = false
		else:
			$Sprite.flip_h = true

func _on_TurnTimer_timeout():
	pass # Replace with function body.

func _on_Area2D_body_entered(body):
	if "Player" in body.name:
		if position.direction_to(body.position).y < -.75:
			if is_spiked:
				body.take_damage()
				$ResetCollisionTimer.start()
			else:
				body.tiny_boost()
				is_stunned = true
				$AnimationPlayer.play("stun")
	#			spawn_death()
	#			queue_free()
		elif !is_stunned:
			body.take_damage()
			$ResetCollisionTimer.start()

func spawn_death():
	var next_death = EnemyDeath.instance()
	get_parent().get_parent().find_node("EnemyDeaths").add_child(next_death)
	next_death.texture = $Sprite.texture
	next_death.hframes = $Sprite.hframes
	next_death.frame = 0
	next_death.position = position

func _on_ResetCollisionTimer_timeout():
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	yield(get_tree().create_timer(0.05), "timeout")
	$Area2D/CollisionShape2D.set_deferred("disabled", false)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "stun":
		$AnimationPlayer.play("walk")
		is_stunned = false
