extends KinematicBody2D

const Projectile = preload("res://src/Projectile.tscn")
const Dust = preload("res://src/effects/Dust.tscn")
const GunSmoke = preload("res://src/effects/GunSmoke.tscn")
const PlayerShadow = preload("res://src/PlayerShadow.tscn")

export(int) var WALK_SPEED = 90
export(int) var WALK_ACCELERATION = 15
export(int) var WALK_DECELERATION = 25
export(int) var FALL_ACCELERATION = 30
export(int) var JUMP_HEIGHT = -60
export(int) var GRAVITY = 90
export(int) var JET_PACK_GRAVITY = -10
export(int) var JET_PACK_ACCELERATION = 30
export(int) var TERMINAL_VELOCITY = 90
export(int) var TERMINAL_JET_PACK_VELOCITY = -150
export(bool) var disable_knockback = false
export(float) var initial_fuel = 1.0
export(Texture) var player_flame = null
export(Texture) var tiny_player_flame = null
export(float) var COYOTE_TIME_BUFFER = 0.2

enum State { IDLE, WALK, JUMP, FALL, DASH, JET_PACK }

var current_state = State.IDLE
var previous_state = State.IDLE
var init = true
var input = Vector2.ZERO
var velocity = Vector2.ZERO
var knockback = Vector2.ZERO
var is_colliding_right_wall = false
var is_colliding_left_wall = false
var can_shoot = true
var can_dash = false
var can_jump = true
var current_fuel = 0.0
var coyote_count = 0.0
var jump_buffer_count = 0.0

func _ready():
	current_fuel = initial_fuel

func _physics_process(delta):
	input.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	if input.x < 0:
		$Sprite.flip_h = true
	elif input.x > 0:
		$Sprite.flip_h = false
	match current_state:
		State.IDLE:
			handle_idle(delta)
		State.WALK:
			handle_walk(delta)
		State.JUMP:
			handle_jump(delta)
		State.FALL:
			handle_fall(delta)
		State.DASH:
			handle_dash(delta)
		State.JET_PACK:
			handle_jet_pack(delta)
	if Input.is_action_just_pressed("ui_shoot") and can_shoot:
		can_shoot = false
		$ShotCooldownTimer.start()
		fire_projectile(position)
	if is_on_floor() and current_fuel < initial_fuel:
		current_fuel = initial_fuel
	if is_on_floor():
		can_jump = true
	knockback = lerp(knockback, Vector2.ZERO, 10 * delta)
	jump_buffer_count -= delta

var time_passed = 0.0
var shadow_increment = 0.01
var next_shadow = 0.01
func handle_jet_pack(delta):
	if init:
		init = false
		time_passed = 0.0
		next_shadow = shadow_increment
		if velocity.y > 0:
			$Tween.interpolate_property(self, "velocity", velocity, Vector2(velocity.x, 25), 0.05, Tween.TRANS_QUAD, Tween.EASE_OUT)
			$Tween.start()
			yield($Tween, "tween_all_completed")
	time_passed += delta
	if time_passed >= next_shadow:
		spawn_shadow()
		next_shadow += shadow_increment
	current_fuel -= delta
	if current_fuel <= 0:
		change_state(State.IDLE)
	elif Input.is_action_just_released("ui_jump"):
		change_state(State.FALL)
	var adjusted_input = input
	if Input.is_action_pressed("ui_lock"):
		adjusted_input = Vector2.ZERO
	velocity.x = lerp(velocity.x, knockback.x + adjusted_input.x * WALK_SPEED, WALK_ACCELERATION * delta)
	velocity.y = max(TERMINAL_JET_PACK_VELOCITY, lerp(velocity.y, knockback.y + velocity.y + JET_PACK_GRAVITY * delta, JET_PACK_ACCELERATION * delta))
	move_and_slide(velocity, Vector2.DOWN)

func handle_dash(delta):
	if init:
		time_passed = 0.0
		next_shadow = shadow_increment
#		modulate.a = 0.0
		can_dash = false
		init = false
		old_walk_speed = WALK_SPEED
		old_walk_acceleration = WALK_ACCELERATION
		old_fall_acceleration = FALL_ACCELERATION
		velocity.y = JUMP_HEIGHT
		spawn_shadow()
#		$ShadowTimer.start()
		WALK_SPEED = old_walk_speed + 75
		WALK_ACCELERATION = old_walk_acceleration + 25
	time_passed += delta
	if time_passed >= next_shadow:
		spawn_shadow()
		next_shadow += shadow_increment
	if velocity.y >= 0:
#		modulate.a = 1.0
#		$ShadowTimer.stop()
		change_state(State.FALL)
	var adjusted_input = input
	if Input.is_action_pressed("ui_lock"):
		adjusted_input = Vector2.ZERO
	WALK_SPEED = lerp(WALK_SPEED, old_walk_speed, 1 * delta)
	WALK_ACCELERATION = lerp(WALK_ACCELERATION, old_walk_acceleration, 25 * delta)
	FALL_ACCELERATION = lerp(FALL_ACCELERATION, old_fall_acceleration + 15, 20 * delta)
	velocity.x = lerp(velocity.x, knockback.x + adjusted_input.x * WALK_SPEED, WALK_ACCELERATION * delta)
	velocity.y = min(0, lerp(velocity.y, knockback.y + velocity.y + GRAVITY * delta, FALL_ACCELERATION * delta))
	move_and_slide(velocity, Vector2.UP)
	if current_state != State.DASH:
		WALK_SPEED = old_walk_speed
		FALL_ACCELERATION = old_fall_acceleration
		WALK_ACCELERATION = old_walk_acceleration

func spawn_shadow():
#	var tiny_shadow = PlayerShadow.instance()
#	get_parent().get_parent().find_node("Shadows").add_child(tiny_shadow)
#	tiny_shadow.position = position + Vector2(0, 12)
#	tiny_shadow.texture = tiny_player_flame
	
	var next_shadow = PlayerShadow.instance()
	get_parent().get_parent().find_node("Shadows").add_child(next_shadow)
	next_shadow.position = position + Vector2(0, 8)
	next_shadow.texture = player_flame

func fire_projectile(starting_position):
#	$AnimationPlayer.play("shoot")
	var next_projectile = Projectile.instance()
	get_parent().get_parent().find_node("Projectiles").add_child(next_projectile)
	next_projectile.projectile_spawn_count = 0
	var projectile_distance_from_player = 24
	if input == Vector2.ZERO:
		if $Sprite.flip_h:
			next_projectile.position = starting_position + Vector2.LEFT * projectile_distance_from_player
			next_projectile.set_direction(Vector2.LEFT)
		else:
			next_projectile.position = starting_position + Vector2.RIGHT * projectile_distance_from_player
			next_projectile.set_direction(Vector2.RIGHT)
	else:
		next_projectile.position = starting_position + input.normalized() * projectile_distance_from_player
		next_projectile.set_direction(input.normalized())
#	spawn_gunsmoke(next_projectile.position)
	var knockback_amount = 32
	if input.y > 0:
		knockback_amount = 100
#		velocity.y = -100
	knockback = next_projectile.direction.rotated(PI) * knockback_amount
	if disable_knockback:
		knockback = Vector2.ZERO

func spawn_gunsmoke(pos):
	var next_smoke = GunSmoke.instance()
	get_parent().add_child(next_smoke)
	next_smoke.position = pos

func spawn_dust():
	return
	var next_dust = Dust.instance()
	get_parent().add_child(next_dust)
	next_dust.position = position + Vector2(rand_range(-4, 4), 16)

func handle_idle(delta):
	if init:
		init = false
		if previous_state != State.FALL:
			$AnimationPlayer.play("idle")
		if previous_state == State.FALL:
			spawn_dust()
	if !is_on_floor():
		change_state(State.FALL)
	elif input.x != 0:
		change_state(State.WALK)
	elif Input.is_action_just_pressed("ui_jump"):
		change_state(State.JUMP)
	var adjusted_input = input
	if Input.is_action_pressed("ui_lock"):
		adjusted_input = Vector2.ZERO
	velocity.y = min(TERMINAL_VELOCITY, lerp(velocity.y, knockback.y + velocity.y + GRAVITY * delta, FALL_ACCELERATION * delta))
	velocity.x = lerp(velocity.x, knockback.x + adjusted_input.x * WALK_SPEED, WALK_DECELERATION * delta)
	move_and_slide(velocity, Vector2.UP)

func handle_walk(delta):
	if init:
		velocity.y = 5
		init = false
		if previous_state != State.FALL:
			$AnimationPlayer.play("walk")
	if !is_on_floor():
		change_state(State.FALL)
	elif Input.is_action_just_pressed("ui_jump"):
		change_state(State.JUMP)
	elif input == Vector2.ZERO:
		change_state(State.IDLE)
	var adjusted_input = input
	if Input.is_action_pressed("ui_lock"):
		adjusted_input = Vector2.ZERO
	velocity.x = lerp(velocity.x, knockback.x + adjusted_input.x * WALK_SPEED, WALK_ACCELERATION * delta)
	move_and_slide(velocity, Vector2.UP)

var old_walk_speed = 0
var old_walk_acceleration = 0
var old_fall_acceleration = 0
func handle_jump(delta):
	if init:
		can_jump = false
		$AnimationPlayer.play("jump_start")
		init = false
		old_walk_speed = WALK_SPEED
		old_walk_acceleration = WALK_ACCELERATION
		old_fall_acceleration = FALL_ACCELERATION
		velocity.y = JUMP_HEIGHT
		WALK_SPEED = old_walk_speed + 30
		WALK_ACCELERATION = old_walk_acceleration + 5
	if velocity.y >= -50:
		$AnimationPlayer.play("jump_peak")
	if velocity.y >= 0:
		change_state(State.FALL)
	elif Input.is_action_just_pressed("ui_jump") and current_fuel > 0 and Globals.HasJetPack:
		change_state(State.JET_PACK)
	elif Input.is_action_just_released("ui_jump"):
		$Tween.interpolate_property(self, "velocity", velocity, Vector2(velocity.x, velocity.y / 4.0), 0.05, Tween.TRANS_QUAD, Tween.EASE_OUT)
		$Tween.start()
		yield($Tween, "tween_all_completed")
		if current_state == State.JUMP:
			change_state(State.FALL)
	var adjusted_input = input
	if Input.is_action_pressed("ui_lock"):
		adjusted_input = Vector2.ZERO
	WALK_SPEED = lerp(WALK_SPEED, old_walk_speed, 5 * delta)
	WALK_ACCELERATION = lerp(WALK_ACCELERATION, old_walk_acceleration, 5 * delta)
	FALL_ACCELERATION = lerp(FALL_ACCELERATION, old_fall_acceleration + 15, 20 * delta)
	velocity.x = lerp(velocity.x, knockback.x + adjusted_input.x * WALK_SPEED, WALK_ACCELERATION * delta)
	velocity.y = min(0, lerp(velocity.y, knockback.y + velocity.y + GRAVITY * delta, FALL_ACCELERATION * delta))
	move_and_slide(velocity, Vector2.UP)
	if current_state != State.JUMP:
		WALK_SPEED = old_walk_speed
		FALL_ACCELERATION = old_fall_acceleration
		WALK_ACCELERATION = old_walk_acceleration

var was_holding_jump = false
var fall_multiplier = 1.0
var current_multiplier = 1.0
func handle_fall(delta):
	if init:
		coyote_count = 0.0
		$AnimationPlayer.play("fall")
		init = false
		current_multiplier = 1.0
		was_holding_jump = Input.is_action_pressed("ui_jump")
		if was_holding_jump:
			fall_multiplier = 1.0
		else:
			fall_multiplier = 2.25
	coyote_count += delta
	if Input.is_action_just_pressed("ui_jump"):
		if coyote_count < COYOTE_TIME_BUFFER and can_jump:
			change_state(State.JUMP)
		else:
			jump_buffer_count = COYOTE_TIME_BUFFER
	if is_on_floor():
		if jump_buffer_count >= 0:
			change_state(State.JUMP)
		elif input == Vector2.ZERO:
			$AnimationPlayer.play("land")
			change_state(State.IDLE)
		else:
			$AnimationPlayer.play("short_land")
			change_state(State.WALK)
	elif was_holding_jump and Input.is_action_just_released("ui_jump"):
		fall_multiplier = 2.25
	elif Input.is_action_pressed("ui_jump") and current_fuel > 0 and Globals.HasJetPack:
		change_state(State.JET_PACK)
	var adjusted_input = input
	if Input.is_action_pressed("ui_lock"):
		adjusted_input = Vector2.ZERO
	current_multiplier = lerp(current_multiplier, fall_multiplier, 25 * delta)
	velocity.x = lerp(velocity.x, knockback.x + adjusted_input.x * WALK_SPEED, WALK_ACCELERATION * delta)
	velocity.y = min(TERMINAL_VELOCITY, lerp(knockback.y + velocity.y, velocity.y + GRAVITY * delta, current_multiplier * FALL_ACCELERATION * delta))
	move_and_slide(velocity, Vector2.UP)

func change_state(next_state):
	init = true
	print("Changing state from %s to %s" % [get_state_name(current_state), get_state_name(next_state)])
	previous_state = current_state
	current_state = next_state

func get_state_name(state):
	match state:
		State.IDLE:
			return "IDLE"
		State.WALK:
			return "WALK"
		State.JUMP:
			return "JUMP"
		State.FALL:
			return "FALL"
		State.DASH:
			return "DASH"
		State.JET_PACK:
			return "JET_PACK"

func _on_RightWallArea_body_entered(body):
	if "Tile" in body.name:
		is_colliding_right_wall = true

func _on_RightWallArea_body_exited(body):
	if "Tile" in body.name:
		is_colliding_right_wall = false

func _on_LeftWallArea_body_entered(body):
	if "Tile" in body.name:
		is_colliding_left_wall = true

func _on_LeftWallArea_body_exited(body):
	if "Tile" in body.name:
		is_colliding_left_wall = false

func _on_ShotCooldownTimer_timeout():
	can_shoot = true

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "land" or anim_name == "short_land":
		if current_state == State.IDLE:
			$AnimationPlayer.play("idle")
		elif current_state == State.WALK:
			$AnimationPlayer.play("walk")
