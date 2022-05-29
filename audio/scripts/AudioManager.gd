extends Node2D

export(bool) var is_muted = false

func _ready():
	normalize_music()

func stop_all_songs():
	for song in $Music.get_children():
		if song.playing:
			song.stop()

func setup_semi_boss():
	$Music/Main.play(0.0)
	$Music/Main.pitch_scale = 1.2

func setup_boss():
	$Music/Main.play(0.0)
	$Music/Main.pitch_scale = 1.2
	AudioServer.set_bus_effect_enabled(1, 0, true)

func setup_secret_room():
	stop_all_songs()

func setup_outro():
	$Music/Main.play(0.0)
	$Music/Main.pitch_scale = 0.75
	AudioServer.set_bus_effect_enabled(1, 0, false)
	AudioServer.set_bus_effect_enabled(1, 1, true)
	AudioServer.set_bus_effect_enabled(1, 2, true)

func normalize_music():
	$Music/Main.pitch_scale = 1.0
	AudioServer.set_bus_effect_enabled(1, 0, false)
	AudioServer.set_bus_effect_enabled(1, 1, false)
	AudioServer.set_bus_effect_enabled(1, 2, false)

func play_song(song_name):
	if is_muted:
		return
	for song in $Music.get_children():
		if song.name == song_name and !song.playing:
			stop_all_songs()
			song.play()

func play_sfx(sfx_name):
	if is_muted:
		return
	for sfx in $SFX.get_children():
		if sfx.name == sfx_name:
			sfx.play()

func is_any_song_playing():
	for song in $Music.get_children():
		if song.playing:
			return true
	return false

func _on_SongStartTimer_timeout():
	$Music/Main.play()
