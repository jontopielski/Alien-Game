extends StaticBody2D

var is_active = true

func _on_Area2D_body_entered(body):
	if "Player" in body.name and is_active:
		crumble()

func set_frame(frame_num):
	$Sprite.frame = frame_num

func crumble():
	is_active = false
	$AnimationPlayer.play("crumble")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "crumble":
		$CollisionShape2D.set_deferred("disabled", true)
		$RespawnTimer.start()

func _on_RespawnTimer_timeout():
	is_active = true
	$AnimationPlayer.play("respawn")
	$CollisionShape2D.set_deferred("disabled", false)
