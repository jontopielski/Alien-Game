extends StaticBody2D

func _physics_process(delta):
	if Globals.PlayerPosition.y + 20 < global_position.y and $CollisionShape2D.disabled:
		$CollisionShape2D.set_deferred("disabled", false)
	if Globals.PlayerPosition.y > global_position.y and !$CollisionShape2D.disabled:
		$CollisionShape2D.set_deferred("disabled", true)

func set_frame(frame):
	$Sprite.frame = frame
