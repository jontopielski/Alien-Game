extends Node2D

const Player = preload("res://src/Player.tscn")
const Spikes = preload("res://src/enemies/Spikes.tscn")
const Smoke = preload("res://src/effects/Smoke.tscn")
const GunUpgrade = preload("res://src/upgrades/GunUpgrade.tscn")
const WhiteCircle = preload("res://src/projectiles/WhiteCircle.tscn")
const Flapper = preload("res://src/enemies/Flapper.tscn")
const Mook = preload("res://src/enemies/Mook.tscn")
const Burger = preload("res://src/upgrades/Burger.tscn")

const TotemSpike = preload("res://src/enemies/TotemSpike.tscn")

export(Array, String) var notable_tiles = ["PinkFlapperEnemy", "FloatingPlatformMechanic", "ThwomperEnemy", "FlapperEnemy", "SpikedMookEnemy", "FallingPlatformMechanic", "MookEnemy", "MushroomMechanic", "RealSpikedMookEnemy", "Spikes_0", "Spikes_1", "Spikes_2", "Spikes_3", "Spikes_4", "Spikes_5", "Spikes_6", "Spikes_7", "Spikes_8", "Spikes_9", "BigMookEnemy", "SpitterEnemy", "LavaBoyEnemy", "SaveMechanic", "ClimberEnemy", "SmallMushroomHeadMechanic", "MediumMushroomHeadMechanic", "LargeMushroomHeadMechanic" ]
export(bool) var use_delays = false

onready var notable_tile_ids = get_notable_tile_ids()
var camera_offset_y = 0

func _ready():
	AudioManager.normalize_music()
#	AudioServer.set_bus_effect_enabled(1, 0, false)
	HUD.show_hud()
	ScreenShader.show_normal_background()
	if Globals.SaveLevel == "Level0":
		Globals.SaveLevel = name
		Globals.SaveCoordinates = $TileMap.world_to_map($DefaultSpawn.position)
	if Helpers.get_level_number(name) >= 7:
		Globals.HasGun = true
	if name == "Level1" and Globals.IsHardcoreMode:
		$Hardcore.show()
	if name == "Level1" and Globals.HasGun:
		if Globals.PreviousLevel == "Level14":
			$TileMap.set_cell(0, 6, -1)
			$TileMap.set_cell(0, 7, -1)
			$TileMap.set_cell(-1, 6, -1)
			$TileMap.set_cell(-1, 7, -1)
			$TileMap.update_bitmask_region(Vector2(-1, 6), Vector2(0, 7))
		else:
			var breakable_tile = $TileMap.tile_set.find_tile_by_name("BreakableMechanic")
			$TileMap.set_cell(0, 6, breakable_tile)
			$TileMap.set_cell(0, 7, breakable_tile)
			$TileMap.set_cell(-1, 6, -1)
			$TileMap.set_cell(-1, 7, -1)
			$TileMap.update_bitmask_region(Vector2(-1, 6), Vector2(0, 7))
	if name == "Level6":
		if !Globals.IsHardcoreMode:
			HUD.set_health(HUD.max_health)
		if Globals.HasGun:
			var big_mook_tiles = $TileMap.get_used_cells_by_id($TileMap.tile_set.find_tile_by_name("BigMookEnemy"))
			$TileMap.set_cellv(big_mook_tiles.front(), TileMap.INVALID_CELL)
			var floating_platform = $TileMap.tile_set.find_tile_by_name("FloatingPlatformMechanic")
			$TileMap.set_cell(3, 8, floating_platform)
			$TileMap.set_cell(4, 8, floating_platform)
			$TileMap.set_cell(14, 8, floating_platform)
			$TileMap.set_cell(13, 8, floating_platform)
			$TileMap.update_bitmask_region(Vector2(3, 8), Vector2(14, 8))
			$TileMap.set_cell(0, 5, -1)
			$TileMap.set_cell(0, 6, -1)
			$TileMap.set_cell(0, 7, -1)
		else:
#			AudioServer.set_bus_effect_enabled(1, 0, true)
			AudioManager.setup_semi_boss()
			var mook_id = $TileMap.tile_set.find_tile_by_name("MookEnemy")
			for mook_tile in $TileMap.get_used_cells_by_id(mook_id):
				$TileMap.set_cellv(mook_tile, TileMap.INVALID_CELL)
			var spiked_mook_id = $TileMap.tile_set.find_tile_by_name("SpikedMookEnemy")
			for mook_tile in $TileMap.get_used_cells_by_id(spiked_mook_id):
				$TileMap.set_cellv(mook_tile, TileMap.INVALID_CELL)
			for i in range(0, 8):
				$TileMap.set_cell(5 + i, 8, TileMap.INVALID_CELL)
	if name == "Level4" and Globals.PreviousLevel == "Level16":
		$TileMap.set_cellv(Vector2(1, -15), -1)
	if name == "Level16" and Globals.HasReceivedRoom16Heart:
		$ExtraHeart.queue_free()
	if name == "Level15" and Globals.HasReceivedRoom15Heart:
		$ExtraHeart.queue_free()
	if name == "Level14" and Globals.HasReceivedRoom14Heart:
		$ExtraHeart.queue_free()
	var did_player_die = Globals.HasDied
	spawn_enemies()
	spawn_player()
	
	if !did_player_die:
		TransitionScreen.level_loaded()
	if name == "Level13":
		AudioManager.setup_boss()
		ScreenShader.show_boss_background()
		Globals.BossRounds = 0
		$TotemPhaseTimer.start()
		Globals.HasJetPack = true
		Globals.HasGun = true
		Globals.IsEagleDead = false
		Globals.IsSummonDead = false
		Globals.IsShootDead = false
		yield(get_tree().create_timer(0.25), "timeout")
		get_tree().call_group("player", "freeze_player")
		
		spawn_all_totems()
		totems_spawned = true
		yield(get_tree().create_timer(2.5), "timeout")
		get_tree().call_group("player", "unfreeze_player")
	
	if name == "Level16" or name == "Level15" or name == "Level14":
		AudioManager.setup_secret_room()
	elif !AudioManager.is_any_song_playing():
		AudioManager.play_song("Main")

var seen_enemy_spawns = []
func summon_flapper():
	if has_spawned_burger:
		return
	var summon_count = 2
	if Globals.BossRounds % 2 == 1:
		summon_count = 1
	for i in range(0, summon_count):
		randomize()
		var random_index = randi() % $EnemySpawns.get_child_count()
		var next_enemy_spawn = $EnemySpawns.get_child(random_index)
		while next_enemy_spawn in seen_enemy_spawns or next_enemy_spawn.position.distance_to(Globals.PlayerPosition) < 64:
			random_index = randi() % $EnemySpawns.get_child_count()
			next_enemy_spawn = $EnemySpawns.get_child(random_index)
		seen_enemy_spawns.push_back(next_enemy_spawn)
		yield(get_tree().create_timer(0.5), "timeout")
		if has_spawned_burger:
			return
		var next_flapper = Mook.instance()
		if Globals.BossRounds % 2 == 1:
			next_flapper = Flapper.instance()
		var next_pos = next_enemy_spawn.position
		$YSort.add_child(next_flapper)
		next_flapper.position = next_pos
		AudioManager.play_sfx("WallBroke")
		spawn_white_circle(next_pos)

var spawn_tile = Vector2(10, -3)
func spawn_all_totems():
	for i in range(0, len(Levels.totems)):
		var next_totem = Levels.totems[i].instance()
		if use_delays:
			yield(get_tree().create_timer(0.25), "timeout")
		var coords = spawn_tile + Vector2(0, -i)
		var tile_location = coords * 16.0 + Vector2(8, 8) + Vector2(-8, 0)
		$YSort.add_child(next_totem)
		next_totem.position = tile_location
		AudioManager.play_sfx("PlatformSpawned")
		spawn_smoke_at_position(tile_location)

func spawn_white_circle(pos):
	var next_circle = WhiteCircle.instance()
	$EnemyDeaths.add_child(next_circle)
	next_circle.position = pos

func screenshake():
	if find_node("AnimationPlayer"):
		$AnimationPlayer.play("screenshake")

func spawn_smoke_at_position(pos):
	var next_smoke = Smoke.instance()
	add_child(next_smoke)
	next_smoke.position = pos

func spawn_gun():
	get_tree().call_group("player", "freeze_player")
	AudioManager.stop_all_songs()
	for child in $Mechanics.get_children():
		if "Falling" in child.name:
			child.crumble_to_death()
	
	for i in range(0, 6):
		yield(get_tree().create_timer(0.35), "timeout")
		var floating_platform = $TileMap.tile_set.find_tile_by_name("FloatingPlatformMechanic")
		if Vector2((3 + i) * 16, 8 * 16).distance_to(Globals.PlayerPosition) > 24:
			$TileMap.set_cell(3 + i, 8, floating_platform)
			spawn_smoke_at_position(Vector2((3 + i) * 16, 8 * 16) + Vector2(8, 4))
		if Vector2((14 - i) * 16, 8 * 16).distance_to(Globals.PlayerPosition) > 24:
			$TileMap.set_cell(14 - i, 8, floating_platform)
			spawn_smoke_at_position(Vector2((14 - i) * 16, 8 * 16) + Vector2(8, 4))
		$TileMap.update_bitmask_region(Vector2((3 + i), 8), Vector2((14 - i), 8))
		AudioManager.play_sfx("PlatformSpawned")
	
	yield(get_tree().create_timer(0.5), "timeout")
	AudioManager.play_sfx("PlatformSpawned")
	spawn_gun_upgrade()
	get_tree().call_group("player", "unfreeze_player")

func grabbed_gun():
	get_tree().call_group("player", "freeze_player")
	$AnimationPlayer.play("gun_upgrade")
	get_tree().call_group("player", "equip_gun")
	yield($AnimationPlayer, "animation_finished")
	get_tree().call_group("player", "unfreeze_player")
	$AnimationPlayer.play("show_shoot")

var is_frozen_until_jump = false
func grabbed_boots():
	get_tree().call_group("player", "freeze_player")
	Globals.HasJetPack = true
	$AnimationPlayer.play("gun_upgrade")
	get_tree().call_group("player", "equip_boots")
	yield($AnimationPlayer, "animation_finished")
	is_frozen_until_jump = true
#	get_tree().call_group("player", "unfreeze_player")
	$Jetpack.show()

func spawn_gun_upgrade():
	var gun_upgrade = GunUpgrade.instance()
	$YSort.add_child(gun_upgrade)
	gun_upgrade.position = Vector2(9.5 * 16, 5.5 * 16)
	spawn_smoke_at_position(Vector2(9.5 * 16, 5.5 * 16))

func get_notable_tile_ids():
	var ids = []
	for tile_name in notable_tiles:
		var tile_id = $TileMap.tile_set.find_tile_by_name(tile_name)
		if tile_id:
			ids.push_back(tile_id)
	return ids

func get_direction(global_pos):
	if global_pos.x < $Camera2D.limit_left + 16:
		return Vector2.LEFT
	elif global_pos.x > $Camera2D.limit_right - 16:
		return Vector2.RIGHT
	elif global_pos.y < $Camera2D.limit_top + 16:
		return Vector2.UP
	elif global_pos.y > $Camera2D.limit_bottom - 16:
		return Vector2.DOWN

func does_tile_exist(_pos):
	return $TileMap.get_cellv($TileMap.world_to_map(_pos)) != TileMap.INVALID_CELL

func spawn_enemies():
	if has_spawned_burger:
		return
	var count = 0
	for tile_id in notable_tile_ids:
		for tile in $TileMap.get_used_cells_by_id(tile_id):
			count += 1
			var tile_name = $TileMap.tile_set.tile_get_name(tile_id)
			if "Enemy" in tile_name:
				var enemy_name = tile_name.substr(0, tile_name.find("Enemy"))
				var enemy_scene = load("res://src/enemies/%s.tscn" % enemy_name)
				if enemy_scene:
					var is_flipped_tile = $TileMap.is_cell_x_flipped(tile.x, tile.y)
					$TileMap.set_cellv(tile, TileMap.INVALID_CELL)
					var next_enemy = enemy_scene.instance()
					$YSort.add_child(next_enemy)
					next_enemy.position = tile * 16 + Vector2(8, 8)
					if enemy_name == "LavaBoy":
						if count % 2 == 0:
							next_enemy.start_pop(1.5)
						else:
							next_enemy.start_pop(0.0)
					elif enemy_name == "Climber":
						next_enemy.set_is_active(true)
					elif enemy_name == "Spitter":
						next_enemy.set_flipped(is_flipped_tile)
			elif "Spikes" in tile_name:
				var next_spike = Spikes.instance()
				$YSort.add_child(next_spike)
				next_spike.position = tile * 16
			elif "Mechanic" in tile_name:
				var mechanic_name = tile_name.substr(0, tile_name.find("Mechanic"))
				var mechanic_scene = load("res://src/mechanics/%s.tscn" % mechanic_name)
				if mechanic_scene:
					var next_mechanic = mechanic_scene.instance()
					$Mechanics.add_child(next_mechanic)
					next_mechanic.position = tile * 16 + Vector2(8, 8)
					if tile == Globals.SaveCoordinates and mechanic_name == "Save":
						if Globals.HasDied and Globals.HasSavedOnce:
							next_mechanic.respawn_player()
					elif mechanic_name == "FallingPlatform":
						var autotile_coords = $TileMap.get_cell_autotile_coord(tile.x, tile.y)
						next_mechanic.set_frame(autotile_coords.y * 3 + autotile_coords.x)
					elif mechanic_name == "FloatingPlatform":
						var autotile_coords = $TileMap.get_cell_autotile_coord(tile.x, tile.y)
						next_mechanic.set_frame(autotile_coords.y * 3 + autotile_coords.x)
					$TileMap.set_cellv(tile, TileMap.INVALID_CELL)

var totems_spawned = false
var current_offset = 0.0
func _process(delta):
	current_offset = lerp(current_offset, Globals.CameraOffsetY, 3 * delta)
	current_offset = min(current_offset, $Camera2D.limit_bottom - ($Camera2D.get_camera_screen_center().y + 120.0))
#	$Camera2D.offset.y = current_offset
	if totems_spawned and Globals.IsEagleDead and Globals.IsShootDead and Globals.IsSummonDead:
		game_won()
	if is_frozen_until_jump and Input.is_action_pressed("ui_jump"):
		is_frozen_until_jump = false
		get_tree().call_group("player", "unfreeze_player")
	if Input.is_action_just_pressed("ui_kill_boss"):
		kill_all_enemies()

func kill_all_enemies():
	Engine.time_scale = 0.5
	yield(get_tree().create_timer(.05), "timeout")
	Engine.time_scale = 1.0
	$SporeGenerator.hide()
	for thing in $YSort.get_children():
		if "Mook" in thing.name or "Flapper" in thing.name or "Totem" in thing.name or "Eagle" in thing.name:
			if thing.has_method("die"):
				thing.die()

var has_spawned_burger = false
func game_won():
	if !has_spawned_burger:
		kill_all_enemies()
		AudioManager.stop_all_songs()
		var next_burger = Burger.instance()
		add_child(next_burger)
#		HUD.reset_health()
		next_burger.position = get_burger_spawn()
		has_spawned_burger = true

func get_burger_spawn():
	for burger_spawn in $BurgerSpawns.get_children():
		if burger_spawn.global_position.distance_to(Globals.PlayerPosition) > 32:
			return burger_spawn.global_position
	return $BurgerSpawns/Position2D.global_position

func spawn_player():
	var spawn_position = Vector2.ZERO
	var is_respawning_at_save = false
	if Globals.SaveLevel == name and Globals.HasDied and Globals.HasSavedOnce:
		spawn_position = Globals.SaveCoordinates * 16 + Vector2(8, 0)
		is_respawning_at_save = true
	elif Globals.PlayerDirection != Vector2.ZERO:
		match Globals.PlayerDirection:
			Vector2.LEFT:
				spawn_position = Vector2($Camera2D.limit_right - 16, Globals.PlayerPosition.y)
			Vector2.RIGHT:
				spawn_position = Vector2($Camera2D.limit_left + 16, Globals.PlayerPosition.y)
			Vector2.UP:
				spawn_position = Vector2(Globals.PlayerPosition.x, $Camera2D.limit_bottom - 16)
			Vector2.DOWN:
				spawn_position = Vector2(Globals.PlayerPosition.x, $Camera2D.limit_top + 16)
#	elif find_node("%sSpawn" % [Globals.PreviousLevel]):
#		spawn_position = find_node("%sSpawn" % [Globals.PreviousLevel]).position
	else:
		spawn_position = $DefaultSpawn.position
	if name == "Level13":
		spawn_position += Vector2(-16, 16)
	var next_player = Player.instance()
	$YSort.add_child(next_player)
	if is_respawning_at_save:
		AudioManager.play_sfx("PlayerRespawned")
		next_player.hide()
		next_player.is_respawning = true
	next_player.position = spawn_position
	next_player.set_flipped(Globals.PlayerFlippedH)
	$Camera2D.position = spawn_position
	$Camera2D.current = true
	var remote_transform = RemoteTransform2D.new()
	next_player.add_child(remote_transform)
	if Globals.PlayerDirection == Vector2.UP and !Globals.HasDied:
		next_player.is_level_switch_jump = true
		next_player.change_state(2)
#	print(spawn_position)
	remote_transform.remote_path = $Camera2D.get_path()
	Globals.HasDied = false

func get_tile_name_at_position(_position):
	var coordinates = $TileMap.world_to_map(_position)
	var tile_index = $TileMap.get_cellv(coordinates)
	if tile_index == $TileMap.INVALID_CELL:
		return ""
	else:
		return $TileMap.tile_set.tile_get_name(tile_index)

func break_rock_at_coords(coords):
	$TileMap.set_cellv(coords, TileMap.INVALID_CELL)
	$TileMap.update_bitmask_region(coords, coords)

func get_level_number_from_position(_position):
	var coordinates = $TileMap.world_to_map(_position)
	var tile_index = $TileMap.get_cellv(coordinates)
	if $TileMap.tile_set.tile_get_name(tile_index) != "LevelNumbers":
		return -1
	else:
		var autotile_coord = $TileMap.get_cell_autotile_coord(coordinates.x, coordinates.y)
		var level_number = (4 * autotile_coord.y) + (1 + autotile_coord.x)
		return level_number

func set_tile_at_position(_position, tile_name):
	var coordinates = $TileMap.world_to_map(_position)
	var tile_id = $TileMap.tile_set.find_tile_by_name(tile_name)
	if tile_id != TileMap.INVALID_CELL:
		$TileMap.set_cellv(coordinates, tile_id)

func get_tile_id_at_coords(coords):
	return $TileMap.get_cellv(coords)

func get_world_to_map(pos):
	return $TileMap.world_to_map(pos)

func _on_SecretCheck_area_entered(area):
	if "Projectile" in area.name:
		screenshake()
		$Message.show()
		$TileMap.set_cellv(Vector2(19, 2), -1)
		$TileMap.set_cellv(Vector2(19, 3), -1)
		$Sprite.hide()
		$Sprite2.hide()
		$SecretCheck.queue_free()

func is_boss_defeated():
	var totem_count = 0
	for enemy in $YSort.get_children():
		if "totem" in enemy.name.to_lower():
			totem_count += 1
	return totem_count == 0

var totem_phases = [ Globals.TotemPhase.SHOOT, Globals.TotemPhase.SUMMON, Globals.TotemPhase.FLY ]
var phase_index = 0
func _on_TotemPhaseTimer_timeout():
	var next_phase = totem_phases[phase_index]
	get_tree().call_group("totem", "activate", next_phase)
	if next_phase == Globals.TotemPhase.SHOOT and Globals.IsShootDead:
		$TotemPhaseTimer.wait_time = 0.15
		$TotemPhaseTimer.start()
	elif next_phase == Globals.TotemPhase.SUMMON and Globals.IsSummonDead:
		$TotemPhaseTimer.wait_time = 0.15
		$TotemPhaseTimer.start()
	elif next_phase == Globals.TotemPhase.FLY and Globals.IsEagleDead:
		$TotemPhaseTimer.wait_time = 0.15
		$TotemPhaseTimer.start()
	else:
		$TotemPhaseTimer.wait_time = 2.0
		$TotemPhaseTimer.start()
	if phase_index + 1 == len(totem_phases):
		Globals.BossRounds += 1
	phase_index = 0 if phase_index + 1 == len(totem_phases) else phase_index + 1

func _on_ExtraHeart_body_entered(body):
	pass # Replace with function body.
