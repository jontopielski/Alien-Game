extends Area2D

func _process(delta):
	rotate(delta * 2.5)

func _on_GunUpgrade_body_entered(body):
	if "Player" in body.name:
		Globals.HasGun = true
		get_tree().call_group("level", "grabbed_gun")
		queue_free()
