extends Control

func _ready():
	AudioManager.stop_all_songs()
	HUD.hide_hud()

func _process(delta):
	if Input.is_action_just_pressed("ui_jump"):
		TransitionScreen.instant_transition_to(Levels.levels[0])
