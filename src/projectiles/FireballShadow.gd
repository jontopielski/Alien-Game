extends Sprite

func set_color(color):
	modulate = color

func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()

func set_frame(_frame):
	frame = _frame

func set_playback_speed(speed):
	$AnimationPlayer.playback_speed = speed

func increment_frame():
	if frame + 1 == 16:
		frame = 0
	else:
		frame += 1
