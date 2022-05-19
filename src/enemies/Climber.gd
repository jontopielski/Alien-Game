extends KinematicBody2D

const PlayerShadow = preload("res://src/PlayerShadow.tscn")

var is_active = false

var direction = Vector2.LEFT
var previous_direction = Vector2.ZERO

func set_is_active(_is_active):
	is_active = _is_active

func _physics_process(delta):
	var collision = move_and_collide(direction * 50 * delta)
	if collision and collision.normal.is_equal_approx(direction.rotated(PI)):
		if direction == Vector2.LEFT or direction == Vector2.RIGHT:
			previous_direction = direction
			direction = Vector2.UP
		elif direction == Vector2.DOWN:
			if previous_direction == Vector2.LEFT:
				direction = Vector2.RIGHT
			else:
				direction = Vector2.LEFT
	if direction.is_equal_approx(Vector2.UP) and !get_tree().current_scene.does_tile_exist(position + Vector2(0, -16)) and !get_tree().current_scene.does_tile_exist(position + Vector2(-16, 0)) and !get_tree().current_scene.does_tile_exist(position + Vector2(16, 0)):
		direction = Vector2.DOWN

func spawn_shadow():
	var next_shadow = PlayerShadow.instance()
	get_parent().get_parent().find_node("Shadows").add_child(next_shadow)
	next_shadow.position = position + Vector2(0, 0)
	next_shadow.texture = $Sprite.texture
	next_shadow.set_playback_speed(1.5)

func _on_Area2D_body_entered(body):
	if "Player" in body.name:
		body.take_damage()

func _on_ShadowTimer_timeout():
	spawn_shadow()
