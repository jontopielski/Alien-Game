extends Node

func change_level(level_number):
	Globals.PreviousLevel = get_tree().current_scene.name
	get_tree().change_scene("res://src/levels/Level%s.tscn" % level_number)

func player_died():
	Globals.HasDied = true
	if get_tree().current_scene.name != Globals.SaveLevel and Globals.SaveLevel != "Level0":
		var level_number = int(Globals.SaveLevel.substr(len(Globals.SaveLevel) - 1, len(Globals.SaveLevel)))
		var level_scene = load("res://src/levels/Level%s.tscn" % level_number)
		TransitionScreen.transition_to(level_scene)
	else:
		var level_number = int(Globals.SaveLevel.substr(len(Globals.SaveLevel) - 1, len(Globals.SaveLevel)))
		var level_scene = load("res://src/levels/Level%s.tscn" % level_number)
		TransitionScreen.transition_to(level_scene)
#		get_tree().current_scene.spawn_player()
	HUD.reset_health()
