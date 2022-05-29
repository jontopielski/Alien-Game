extends Node2D

export(bool) var update_sprite = false setget set_update_sprite
export(float) var y_offset = 1.0 setget set_y_offset
export(int) var num_patties = 1 setget set_num_patties
export(Array, Color) var patty_colors = []
export(float) var darkened_amount = 0.0
export(float) var lightened_amount = 0.0

var seed_locations = []

func set_update_sprite(_update_sprite):
	update()

func set_num_patties(_num_patties):
	num_patties = _num_patties
	update()

func set_y_offset(_y_offset):
	y_offset = _y_offset
	update()

func _ready():
	randomize()
	for i in range(0, 4):
		for j in range(0, 4):
			seed_locations.push_back(Vector2(-16 + i * 8, -16 + j * 8) + Vector2(rand_range(-4, 4), rand_range(-4, 4)))

func _draw():
	var base_index = 0
	# Bottom bun
	for i in range(0, 3):
		draw_circle(Vector2(0, -base_index - i), 25 - i, Color("#b77e47"))
		base_index += y_offset
	# Pink sauce
	for i in range(0, 1):
		draw_circle(Vector2(0, -base_index - i), 25, Color("#f25597"))
		base_index += y_offset
	# Patty
	for j in range(0, num_patties):
		var patty_color = patty_colors[j]
		for i in range(0, 4):
			draw_circle(Vector2(0, -base_index - i), 27 + j, patty_color)
			base_index += y_offset
		# Cheese
		for i in range(0, 2):
			draw_circle(Vector2(0, -base_index - i), 28, Color("#ff9700"))
			base_index += y_offset
	
	# Lettuce
	for i in range(0, 2):
		draw_circle(Vector2(0, -base_index - i), 28, Color("#27de3d"))
		base_index += y_offset
	# Tomato
	for i in range(0, 3):
		draw_circle(Vector2(0, -base_index - i), 25, Color("#db1616"))
		base_index += y_offset
	# Top Bun
	for i in range(0, 3):
		draw_circle(Vector2(0, -base_index - i), 27 - i * 2, Color("#b77e47"))
#		for j in range(0, 16):
#			draw_circle(Vector2(0 + seed_locations[j].x, -base_index - i + seed_locations[j].y) + Vector2(4, 4), 1.25, Color("#f2efc7"))
		base_index += y_offset
