extends Node2D

const Player = preload("res://src/Player.tscn")
const Spikes = preload("res://src/enemies/Spikes.tscn")

var camera_offset_y = 0

func _ready():
	if Globals.SaveLevel == "Level0":
		Globals.SaveLevel = name
		Globals.SaveCoordinates = $TileMap.world_to_map($DefaultSpawn.position)
	spawn_enemies()
	spawn_player()

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
	for tile in $TileMap.get_used_cells():
		count += 1
		var tile_id = $TileMap.get_cellv(tile)
		var tile_name = $TileMap.tile_set.tile_get_name(tile_id)
		if "Enemy" in tile_name:
			var enemy_name = tile_name.substr(0, tile_name.find("Enemy"))
			var enemy_scene = load("res://src/enemies/%s.tscn" % enemy_name)
			if enemy_scene:
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
		elif "Spikes" in tile_name:
			var next_spike = Spikes.instance()
			$YSort.add_child(next_spike)
			next_spike.position = tile * 16
		elif "Mechanic" in tile_name:
			var mechanic_name = tile_name.substr(0, tile_name.find("Mechanic"))
			var mechanic_scene = load("res://src/mechanics/%s.tscn" % mechanic_name)
			if mechanic_scene:
				$TileMap.set_cellv(tile, TileMap.INVALID_CELL)
				var next_mechanic = mechanic_scene.instance()
				$Mechanics.add_child(next_mechanic)
				next_mechanic.position = tile * 16 + Vector2(8, 8)
				if tile == Globals.SaveCoordinates and mechanic_name == "Save":
					if Globals.HasDied and Globals.HasSavedOnce:
						next_mechanic.respawn_player()
				elif mechanic_name == "FallingPlatform":
					if count % 2 == 0:
						next_mechanic.set_frame(1)
					else:
						next_mechanic.set_frame(0)

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

func get_world_to_map(pos):
	return $TileMap.world_to_map(pos)
