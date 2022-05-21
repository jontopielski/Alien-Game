extends Area2D

func _process(delta):
	rotate(delta * 2.5)

func _on_SecretGun_body_entered(body):
	if "Player" in body.name:
		Globals.HasBlueBullet = true
		queue_free()
