extends Node2D

const Spore = preload("res://src/effects/Spore.tscn")

export(Rect2) var rect = Rect2(Vector2.ZERO, Vector2(320, 240))
export(int) var desired_spores = 1000

func _ready():
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

func _on_Timer_timeout():
	var spore_count = $Spores.get_child_count()
	for i in range(0, min(rand_range(10, 25), desired_spores - spore_count)):
		randomize()
		var next_spore_location = Vector2(rand_range(rect.position.x, rect.position.x + rect.size.x), rect.position.y + rect.size.y)
		spawn_spore(next_spore_location)
