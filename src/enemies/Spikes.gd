extends Area2D

func _on_Spikes_area_entered(area):
	pass # Replace with function body.

func _on_Spikes_body_entered(body):
	if "Player" in body.name:
		body.take_damage()
		yield(get_tree().create_timer(1.05), "timeout")
		$CollisionShape2D.set_deferred("disabled", true)
		$CollisionShape2D.set_deferred("disabled", false)
