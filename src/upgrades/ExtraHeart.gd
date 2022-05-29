extends Area2D

func _on_ExtraHeart_body_entered(body):
	if "Player" in body.name:
		HUD.max_health += 1
		HUD.set_health(HUD.max_health)
		AudioManager.play_sfx("Upgrade")
		match get_tree().current_scene.name:
			"Level16":
				Globals.HasReceivedRoom16Heart = true
			"Level15":
				Globals.HasReceivedRoom15Heart = true
			"Level14":
				Globals.HasReceivedRoom14Heart = true
		queue_free()
