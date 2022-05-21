extends Node2D

const Player = preload("res://src/Player.tscn")
const Spikes = preload("res://src/enemies/Spikes.tscn")
const Smoke = preload("res://src/effects/Smoke.tscn")
const GunUpgrade = preload("res://src/upgrades/GunUpgrade.tscn")

export(Array, String) var notable_tiles = [ "FlapperEnemy", "SpikedMookEnemy", "FallingPlatformMechanic", "MookEnemy", "MushroomMechanic", "RealSpikedMookEnemy", "Spikes_0", "Spikes_1", "Spikes_2", "Spikes_3", "Spikes_4", "Spikes_5", "Spikes_6", "Spikes_7", "Spikes_8", "Spikes_9", "BigMookEnemy", "SpitterEnemy", "LavaBoyEnemy", "SaveMechanic", "ClimberEnemy", "SmallMushroomHeadMechanic", "MediumMushroomHeadMechanic", "LargeMushroomHeadMechanic" ]

onready var notable_tile_ids = get_notable_tile_ids()
var camera_offset_y = 0

func _ready():
	if Globals.SaveLevel == "Level0":
		Globals.SaveLevel = name
		Globals.SaveCoordinates = $TileMap.world_to_map($DefaultSpawn.position)
	if Helpers.get_level_number(name) >= 7:
		Globals.HasGun = true
	if name == "Level6":
		HUD.set_health(HUD.max_health)
		if Globals.HasGun:
			var big_mook_tiles = $TileMap.get_used_cells_by_id($TileMap.tile_set.find_tile_by_name("BigMookEnemy"))
			$TileMap.set_cellv(big_mook_tiles.front(), TileMap.INVALID_CELL)
			var floating_platform = $TileMap.tile_set.find_tile_by_name("FloatingPlatformMechanic")
			$TileMap.set_cell(4, 10, floating_platform)
			$TileMap.set_cell(5, 10, floating_platform)
			$TileMap.set_cell(14, 10, floating_platform)
			$TileMap.set_cell(15, 10, floating_platform)
			$TileMap.update_bitmask_region(Vector2(4, 10), Vector2(15, 10))
		else:
			var mook_id = $TileMap.tile_set.find_tile_by_name("MookEnemy")
			for mook_tile in $TileMap.get_used_cells_by_id(mook_id):
				$TileMap.set_cellv(mook_tile, TileMap.INVALID_CELL)
			var spiked_mook_id = $TileMap.tile_set.find_tile_by_name("SpikedMookEnemy")
			for mook_tile in $TileMap.get_used_cells_by_id(spiked_mook_id):
				$TileMap.set_cellv(mook_tile, TileMap.INVALID_CELL)
			for i in range(0, 8):
				$TileMap.set_cell(6 + i, 10, TileMap.INVALID_CELL)
	if name == "Level4" and Globals.PreviousLevel == "Level16":
		$TileMap.set_cellv(Vector2(1, -15), -1)
	var did_player_die = Globals.HasDied
	spawn_enemies()
	spawn_player()
	if !did_player_die:
		TransitionScreen.level_loaded()

func screenshake():
	if find_node("AnimationPlayer"):
		$AnimationPlayer.play("screenshake")

func spawn_smoke_at_position(pos):
	var next_smoke = Smoke.instance()
	add_child(next_smoke)
	next_smoke.position = pos

func spawn_gun():
	get_tree().call_group("player", "freeze_player")
	
	for child in $Mechanics.get_children():
		if "Falling" in child.name:
			child.crumble_to_death()
	
	for i in range(0, 6):
		yield(get_tree().create_timer(0.35), "timeout")
		var floating_platform = $TileMap.tile_set.find_tile_by_name("FloatingPlatformMechanic")
		if Vector2((4 + i) * 16, 10 * 16).distance_to(Globals.PlayerPosition) > 24:
			$TileMap.set_cell(4 + i, 10, floating_platform)
			spawn_smoke_at_position(Vector2((4 + i) * 16, 10 * 16) + Vector2(8, 4))
		if Vector2((15 - i) * 16, 10 * 16).distance_to(Globals.PlayerPosition) > 24:
			$TileMap.set_cell(15 - i, 10, floating_platform)
			spawn_smoke_at_position(Vector2((15 - i) * 16, 10 * 16) + Vector2(8, 4))
		$TileMap.update_bitmask_region(Vector2((4 + i), 10), Vector2((15 - i), 10))
	
	yield(get_tree().create_timer(0.5), "timeout")
	
	spawn_gun_upgrade()
	
	get_tree().call_group("player", "unfreeze_player")

func grabbed_gun():
	get_tree().call_group("player", "freeze_player")
	$AnimationPlayer.play("gun_upgrade")
	get_tree().call_group("player", "equip_gun")
	yield($AnimationPlayer, "animation_finished")
	get_tree().call_group("player", "unfreeze_player")

func spawn_gun_upgrade():
	var gun_upgrade = GunUpgrade.instance()
	$YSort.add_child(gun_upgrade)
	gun_upgrade.position = Vector2(9.5 * 16, 7.5 * 16)
	spawn_smoke_at_position(Vector2(9.5 * 16, 7.5 * 16))

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
					$TileMap.set_cellv(tile, TileMap.INVALID_CELL)

var current_offset = 0.0
func _process(delta):
	current_offset = lerp(current_offset, Globals.CameraOffsetY, 3 * delta)
	current_offset = min(current_offset, $Camera2D.limit_bottom - ($Camera2D.get_camera_screen_center().y + 120.0))
	$Camera2D.offset.y = current_offset

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
	var next_player = Player.instance()
	$YSort.add_child(next_player)
	if is_respawning_at_save:
		next_player.hide()
		next_player.is_respawning = true
	next_player.position = spawn_position
	next_player.find_node("Sprite").flip_h = Globals.PlayerFlippedH
	$Camera2D.position = spawn_position
	$Camera2D.current = true
	var remote_transform = RemoteTransform2D.new()
	next_player.add_child(remote_transform)
	if Globals.PlayerDirection == Vector2.UP and !Globals.HasDied:
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
