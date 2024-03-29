extends Node

const Intro = preload("res://src/menus/Intro.tscn")

func change_level(level_number):
	Globals.PreviousLevel = get_tree().current_scene.name
	var next_level = Levels.levels[level_number - 1]
	TransitionScreen.instant_transition_to(next_level)
#	get_tree().change_scene_to(next_level)
#	get_tree().change_scene("res://src/levels/Level%s.tscn" % level_number)

func player_died():
	Globals.HasDied = true
	if Globals.IsHardcoreMode:
		TransitionScreen.transition_to(Intro)
	elif get_tree().current_scene.name != Globals.SaveLevel and Globals.SaveLevel != "Level0":
		var level_number = get_level_number(Globals.SaveLevel)
		var level_scene = Levels.levels[level_number - 1]
		TransitionScreen.transition_to(level_scene)
	else:
		var level_number = get_level_number(Globals.SaveLevel)
		var level_scene = Levels.levels[level_number - 1]
		TransitionScreen.transition_to(level_scene)
#		get_tree().current_scene.spawn_player()
	HUD.reset_health()

func get_level_number(scene_name):
	if len(scene_name) == 6:
		return int(scene_name.substr(len(scene_name) - 1, len(scene_name)))
	else:
		return int(scene_name.substr(len(scene_name) - 2, len(scene_name)))
