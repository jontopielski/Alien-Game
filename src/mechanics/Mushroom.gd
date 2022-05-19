extends Area2D

func _on_Mushroom_body_entered(body):
	if "Player" in body.name:
		$AnimationPlayer.play("bounce")
		body.big_boost()
