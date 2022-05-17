extends Node2D

func remove_tile_from_position(pos):
	var coordinates = $TileMap.world_to_map(pos)
	$TileMap.set_cellv(coordinates, TileMap.INVALID_CELL)
	$TileMap.update_bitmask_area(coordinates)

func _process(delta):
	if Input.is_action_just_pressed("ui_screenshot") and OS.is_debug_build():
		var image = get_viewport().get_texture().get_data()
		image.flip_y()
		image.save_png("C:\\Users\\jonto\\Desktop\\Game_Screenshot_%s.png" % str(randi() % 1000))
