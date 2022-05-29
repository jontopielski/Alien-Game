extends Node2D

const Spore = preload("res://src/effects/Spore.tscn")
const BaseSpore = preload("res://sprites/particles/MushroomSpore.png")

export(Rect2) var rect = Rect2(Vector2.ZERO, Vector2(320, 240))
export(int) var desired_spores = 1000
export(Array, Texture) var spore_textures = [BaseSpore]
export(bool) var is_active = true
export(Vector2) var direction = Vector2.UP
export(bool) var use_direction = false
export(int) var foreground_probability = 4
export(bool) var follow_player = false
var spore_index = 0

func _ready():
	if is_active:
		spawn_initial_spores()

func spawn_initial_spores():
	for i in range(0, desired_spores):
		randomize()
		var next_spore_location = Vector2(rand_range(rect.position.x, rect.position.x + rect.size.x), rand_range(rect.position.y, rect.position.y + rect.size.y))
		spawn_spore(next_spore_location)

func spawn_spore(next_spore_location):
	var next_spore = Spore.instance()
	$Spores.add_child(next_spore)
	next_spore.position = next_spore_location
	next_spore.bounds = rect
	next_spore.texture = spore_textures[spore_index]
	if use_direction:
		next_spore.set_direction(direction)
	if foreground_probability > 0 and randi() % foreground_probability == 0:
		next_spore.z_index = 1
	spore_index = 0 if spore_index == len(spore_textures) - 1 else spore_index + 1
	next_spore.follow_player = follow_player

func _on_Timer_timeout():
	if !is_active:
		return
	var spore_count = $Spores.get_child_count()
	for i in range(0, min(rand_range(10, 25), desired_spores - spore_count)):
		randomize()
		var next_spore_location = Vector2(rand_range(rect.position.x, rect.position.x + rect.size.x), rect.position.y + rect.size.y)
		spawn_spore(next_spore_location)
