extends Sprite

func set_color(color):
	modulate = color

func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()
