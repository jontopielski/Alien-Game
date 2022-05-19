extends Sprite

func set_color(color):
	modulate = color

func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()

func set_playback_speed(speed):
	$AnimationPlayer.playback_speed = speed
