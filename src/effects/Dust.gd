extends CPUParticles2D

func _ready():
	emitting = true

func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()

func _on_Timer_timeout():
	queue_free()
