extends Node2D

export(bool) var is_muted = false

func stop_all_songs():
	for song in $Music.get_children():
		if song.playing:
			song.stop()

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
