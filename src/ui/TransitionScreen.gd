extends CanvasLayer

var next_scene = null

func _ready():
	$Background.hide()
	$InstantBg.hide()

func transition_to(scene):
	$Background.show()
	$InstantBg.hide()
	get_tree().paused = true
	next_scene = scene
	$AnimationPlayer.play("fade_to_black")

func instant_transition_to(scene):
	$Background.hide()
	$InstantBg.show()
#	get_tree().paused = true
	next_scene = scene
	$AnimationPlayer.play("instant_fade_to_black")

func slow_transition_to(scene):
	$Background.show()
	next_scene = scene
	$AnimationPlayer.play("slow_fade_to_black")

func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"fade_to_black", "slow_fade_to_black":
			get_tree().change_scene_to(next_scene)
			$AnimationPlayer.play("fade_to_normal")
			$ResumeTimer.start()
		"fade_to_normal":
			$Background.hide()
		"instant_fade_to_black":
			get_tree().paused = false
			get_tree().change_scene_to(next_scene)
		"instant_fade_to_normal":
			$InstantBg.hide()

func level_loaded():
	$AnimationPlayer.play("instant_fade_to_normal")

func _on_ResumeTimer_timeout():
	get_tree().paused = false
