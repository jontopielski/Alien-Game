extends StaticBody2D

const EnemyDeath = preload("res://src/enemies/EnemyDeath.tscn")
const BounceShot = preload("res://src/projectiles/BounceShot.tscn")

var spit_direction = Vector2.LEFT

func set_flipped(_flipped):
	if _flipped:
		$PreStartTimer.wait_time = 2.5
		$PreStartTimer.start()
		spit_direction = Vector2.RIGHT
		$Sprite.flip_h = true
	else:
		$PreStartTimer.start()

func spit():
	AudioManager.play_sfx("Fireball")
	$AnimationPlayer.play("spit")
	var next_shot = BounceShot.instance()
	next_shot.direction = spit_direction
	get_parent().add_child(next_shot)
	if spit_direction == Vector2.LEFT:
		next_shot.position = position + $LeftShot.position
	else:
		next_shot.position = position + $RightShot.position

func spawn_death():
	var next_death = EnemyDeath.instance()
	get_parent().get_parent().find_node("EnemyDeaths").add_child(next_death)
	next_death.texture = $Sprite.texture
	next_death.hframes = $Sprite.hframes
	next_death.position = position

func take_damage():
	spawn_death()
	queue_free()

func _on_SpitTimer_timeout():
	spit()

func _on_PreStartTimer_timeout():
	spit()
	$SpitTimer.start()
