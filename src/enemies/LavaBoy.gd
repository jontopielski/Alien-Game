extends KinematicBody2D

const PlayerShadow = preload("res://src/PlayerShadow.tscn")

export(float) var GRAVITY = 25
export(int) var TERMINAL_VELOCITY = 200

var direction = Vector2.UP
var starting_position = Vector2.ZERO

var velocity = Vector2.ZERO
var is_active = false

func _ready():
	hide()

func spawn_shadow():
	var next_shadow = PlayerShadow.instance()
	get_parent().get_parent().find_node("Shadows").add_child(next_shadow)
	next_shadow.position = position + Vector2(0, 0)
	next_shadow.texture = $Sprite.texture
	next_shadow.set_playback_speed(2)

func start_pop(time_offset):
	yield(get_tree().create_timer(0.2), "timeout")
	if time_offset > 0:
		$PrePopTimer.wait_time = time_offset
		$PrePopTimer.start()
	else:
		$CheckTimer.start()
		can_check = false
		is_active = true
		if global_position.distance_to(Globals.PlayerPosition) < 240:
			AudioManager.play_sfx("Fireball")
		$AnimationPlayer.play("load")
		velocity.y = -250
		$PopTimer.start()
		yield(get_tree().create_timer(0.05), "timeout")
		show()

func _physics_process(delta):
	if is_active:
		spawn_shadow()
		velocity.y = min(TERMINAL_VELOCITY, velocity.y + GRAVITY)
		move_and_slide(velocity, Vector2.UP)
		if position.y > starting_position.y - 32 and can_check:
			$AnimationPlayer.play("fade")
		if position.y > starting_position.y and can_check:
			is_active = false
			hide()

func _on_Area2D_body_entered(body):
	if "Player" in body.name:
		body.take_damage()

func _on_PositionTimer_timeout():
	position += Vector2(0, 24)
	starting_position = position

func _on_PopTimer_timeout():
	$CheckTimer.start()
	$AnimationPlayer.play("load")
	can_check = false
	is_active = true
	if global_position.distance_to(Globals.PlayerPosition) < 240:
		AudioManager.play_sfx("Fireball")
	velocity.y = -250
	$PopTimer.start()
	yield(get_tree().create_timer(0.05), "timeout")
	show()

func _on_PrePopTimer_timeout():
	$CheckTimer.start()
	$AnimationPlayer.play("load")
	can_check = false
	is_active = true
	velocity.y = -250
	if global_position.distance_to(Globals.PlayerPosition) < 240:
		AudioManager.play_sfx("Fireball")
	$PopTimer.start()
	yield(get_tree().create_timer(0.05), "timeout")
	show()

var can_check = false
func _on_CheckTimer_timeout():
	can_check = true
