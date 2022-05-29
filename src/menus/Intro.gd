extends Control

func _ready():
	reset_state()
	AudioManager.stop_all_songs()
	HUD.current_health = 3
	HUD.max_health = 3
	HUD.reset_health()
	HUD.hide_hud()

func _process(delta):
	if Input.is_action_just_pressed("ui_jump"):
		Globals.IsHardcoreMode = false
		TransitionScreen.instant_transition_to(Levels.levels[0])
		HUD.time_start = OS.get_unix_time()
	elif Input.is_action_just_pressed("ui_hardcore"):
		Globals.IsHardcoreMode = true
		TransitionScreen.instant_transition_to(Levels.levels[0])
		HUD.time_start = OS.get_unix_time()

func reset_state():
	Globals.HasJetPack = false
	Globals.HasGun = false

	Globals.IsHardcoreMode = false
	Globals.PreviousLevel = "Level0"
	Globals.SaveLevel = "Level0"
	Globals.SaveCoordinates = Vector2.ZERO
	Globals.HasDied = false
	Globals.HasSavedOnce = false
	Globals.HasBlueBullet = false
	Globals.HasReceivedRoom16Heart = false
	Globals.HasReceivedRoom15Heart = false
	Globals.HasReceivedRoom14Heart = false
	Globals.BossRounds = 0
	Globals.IsEagleDead = false
	Globals.IsSummonDead = false
	Globals.IsShootDead = false

	Globals.PlayerInput = Vector2.ZERO
	Globals.CameraOffsetY = 0
	Globals.PlayerDirection = Vector2.ZERO
	Globals.PlayerPosition = Vector2.ZERO
	Globals.PlayerFlippedH = false
