extends Control

export(int) var num_patties = 3

func get_readable_time():
	var time_now = OS.get_unix_time()
	var elapsed = time_now - HUD.time_start
	var minutes = elapsed / 60
	var seconds = elapsed % 60
	var str_elapsed = "%02d : %02d" % [minutes, seconds]
	return str_elapsed

func _ready():
	if Globals.IsHardcoreMode:
		$Background.color = Color("#f25597")
	$Text.visible_characters = 0
	$Credits.visible_characters = 0
	$Thanks.visible_characters = 0
	$Time.visible_characters = 0
	$Time.text = get_readable_time()
	if Globals.IsHardcoreMode:
		$Time.text += " [Hardcore]"
	AudioManager.stop_all_songs()
	HUD.hide_hud()
	num_patties = HUD.max_health - 2
	match num_patties:
		1:
			$SporeGenerator_1.show()
			$SporeGenerator_2.hide()
			$SporeGenerator_3.hide()
			$Text.text = "You found the single patty!"
		2:
			$SporeGenerator_1.hide()
			$SporeGenerator_2.show()
			$SporeGenerator_3.hide()
			$Text.text = "You found the double patty!"
		3:
			$SporeGenerator_1.hide()
			$SporeGenerator_2.hide()
			$SporeGenerator_3.show()
			$Text.text = "You found the triple patty!"
	$StackedSprite.set_num_patties(num_patties)
	$Tween.interpolate_property($Text, "visible_characters", 0, len($Text.text), 0.1 * len($Text.text), Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()

var last_character_count = 0
func _on_Tween_tween_step(object, key, elapsed, value):
	if object == $Text:
		if int(value) > int(last_character_count) and int(last_character_count) < len($Text.text) - 5:
			last_character_count = int(value)
			AudioManager.play_sfx("UI")
	elif object == $Credits:
		if int(value) > int(last_character_count) and int(last_character_count) < len($Credits.text) - 9:
			last_character_count = int(value)
			AudioManager.play_sfx("UISkip")
	elif object == $Time:
		if int(value) > int(last_character_count) and int(last_character_count) < len($Time.text):
			last_character_count = int(value)
			AudioManager.play_sfx("UI")
	elif object == $Thanks:
		if int(value) > int(last_character_count) and int(last_character_count) < len($Thanks.text) - 3:
			last_character_count = int(value)
			AudioManager.play_sfx("UI")

func _on_Tween_tween_completed(object, key):
	if object == $Text:
		yield(get_tree().create_timer(1.0), "timeout")
		last_character_count = 0
		$Tween.interpolate_property($Time, "visible_characters", 0, len($Time.text), 0.1 * len($Time.text), Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$Tween.start()
	if object == $Time:
		yield(get_tree().create_timer(1.0), "timeout")
		last_character_count = 0
		$Tween.interpolate_property($Thanks, "visible_characters", 0, len($Thanks.text), 0.1 * len($Thanks.text), Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$Tween.start()
	if object == $Thanks:
		yield(get_tree().create_timer(1.0), "timeout")
		last_character_count = 0
		$Tween.interpolate_property($Credits, "visible_characters", 0, len($Credits.text), 0.05 * len($Credits.text), Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$Tween.start()
