extends Area2D

func _on_GunUpgrade_body_entered(body):
	if "Player" in body.name:
		Globals.HasGun = true
		get_tree().call_group("level", "grabbed_gun")
		AudioManager.play_sfx("Upgrade")
		queue_free()
