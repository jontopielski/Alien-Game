extends Area2D

const Explosion = preload("res://src/TinyExplosion.tscn")
const ShotExplosion = preload("res://src/effects/ShotExplosion.tscn")
const CircleExplosion = preload("res://src/effects/CircleExplosion.tscn")
const Marker = preload("res://src/projectiles/Marker.tscn")
const BlueBullet = preload("res://sprites/player/BlueBullet.png")

export(int) var SPEED = 250
export(int) var ACCELERATION = 30

export(Color) var color_one = Color.white
export(Color) var color_two = Color.black

var direction = Vector2.ZERO
var velocity = Vector2.ZERO
var projectile_spawn_count = 0

func set_direction(dir):
	direction = dir.normalized()
	$Sprite.rotation = direction.angle()

func set_blue_bullet():
	pass

func _physics_process(delta):
	if direction != Vector2.ZERO:
		velocity = lerp(velocity, direction * SPEED * delta, ACCELERATION * delta)
		position += velocity

func _on_Projectile_body_entered(body):
	if "Tile" in body.name:
		for check_pos in $TileChecks.get_children():
			var tile_name = get_tree().current_scene.get_tile_name_at_position(check_pos.global_position)
			var coords = get_tree().current_scene.get_world_to_map(check_pos.global_position)
			if "Breakable" in tile_name:
				get_tree().current_scene.break_rock_at_coords(coords)
				break
		spawn_explosion()
		queue_free()
	elif body.has_method("take_damage") and !"Player" in body.name:
		body.take_damage()
		spawn_explosion()
		queue_free()

func spawn_explosion():
	var next_explosion = CircleExplosion.instance()
	get_parent().add_child(next_explosion)
	next_explosion.position = position

func _on_Timer_timeout():
	var next_color_one = color_two
	var next_color_two = color_one
	color_one = next_color_one
	color_two = next_color_two
	update()

func spawn_marker(pos):
	var next_marker = Marker.instance()
	get_parent().add_child(next_marker)
	next_marker.position = pos

func _on_DeathTimer_timeout():
	spawn_explosion()
	queue_free()

func _on_SpawnTimer_timeout():
	$SpawnTimer.stop()
	if projectile_spawn_count > 0:
		var next_projectile = load("res://src/Projectile.tscn").instance()
		get_parent().add_child(next_projectile)
		next_projectile.projectile_spawn_count = projectile_spawn_count - 1
		next_projectile.set_direction(direction)
		next_projectile.position = position - direction * 8
