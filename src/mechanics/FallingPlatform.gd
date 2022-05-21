extends StaticBody2D

var is_active = true

var is_crumbling_to_death = false

func _on_Area2D_body_entered(body):
	if "Player" in body.name and is_active:
		crumble()

func crumble_to_death():
	is_crumbling_to_death = true
	$AnimationPlayer.play("fast_crumble")

func set_frame(frame_num):
	$Sprite.frame = frame_num

func crumble():
	is_active = false
	$AnimationPlayer.play("crumble")

func fast_crumble():
	is_active = false
	$AnimationPlayer.play("fast_crumble")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "crumble" or anim_name == "fast_crumble":
		if is_crumbling_to_death:
			queue_free()
		else:
			$CollisionShape2D.set_deferred("disabled", true)
			$RespawnTimer.start()

func _on_RespawnTimer_timeout():
	is_active = true
	var is_player_near = global_position.distance_to(Globals.PlayerPosition) < 8
	while is_player_near:
		yield(get_tree().create_timer(0.1), "timeout")
		is_player_near = global_position.distance_to(Globals.PlayerPosition) < 8
	$AnimationPlayer.play("respawn")
	$CollisionShape2D.set_deferred("disabled", false)
