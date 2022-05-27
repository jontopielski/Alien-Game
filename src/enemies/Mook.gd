extends KinematicBody2D

const EnemyDeath = preload("res://src/enemies/EnemyDeath.tscn")

export(int) var SPEED = 60
export(int) var ACCELERATION = 15
export(int) var GRAVITY = 25
export(int) var TERMINAL_VELOCITY = 100
export(bool) var is_fake_spiked = false
export(bool) var is_real_spiked = false
export(Texture) var fake_spiked_texture = null
export(Texture) var real_spiked_texture = null

var direction = Vector2.LEFT
var velocity = Vector2.ZERO
var is_stunned = false

func _ready():
	$AnimationPlayer.play("walk")
	if is_fake_spiked:
		direction = Vector2.RIGHT
		$Sprite.flip_h = true
		$Sprite.texture = fake_spiked_texture
	elif is_real_spiked:
		$Sprite.texture = real_spiked_texture

func _physics_process(delta):
	if is_stunned:
		velocity.x = 0
		velocity.y = min(TERMINAL_VELOCITY, velocity.y + GRAVITY)
		move_and_slide(velocity, Vector2.UP)
		return
	
	if !$TurnTimer.is_stopped():
		velocity.x = 0
	velocity.x = lerp(velocity.x, direction.x * SPEED * 1.1, ACCELERATION * delta)
	velocity.y = min(TERMINAL_VELOCITY, velocity.y + GRAVITY)
	move_and_slide(velocity, Vector2.UP)
	var is_on_edge = is_on_edge(direction, 8)
	
	if (is_on_wall() or is_on_edge) and $TurnTimer.is_stopped():
		if !is_on_edge:
			velocity.y = -100
		$TurnTimer.start()
		direction = direction.rotated(PI).round()
		if direction.x < 0:
			$Sprite.flip_h = false
		else:
			$Sprite.flip_h = true

func is_on_edge(dir, check_distance):
	var check_position = global_position + (dir * check_distance) + (Vector2.DOWN * 16)
	var coords = get_tree().current_scene.get_world_to_map(check_position)
	var look_ahead_tile = get_tree().current_scene.get_tile_id_at_coords(coords)
	var look_ahead_name = get_tree().current_scene.get_tile_name_at_position(check_position)
	if look_ahead_tile == -1 or "Lava" in look_ahead_name:
		return true

func _on_TurnTimer_timeout():
	pass # Replace with function body.

func _on_Area2D_body_entered(body):
	if "Player" in body.name:
		if position.direction_to(body.position).y < -.5:
			if is_real_spiked:
				body.take_damage()
				$ResetCollisionTimer.start()
			else:
				body.tiny_boost()
				is_stunned = true
				$AnimationPlayer.play("stun")
				die()
		elif !is_stunned:
			body.take_damage()
			$ResetCollisionTimer.start()

func take_damage():
	die()

func die():
	spawn_death()
	queue_free()

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
