extends KinematicBody2D

const Projectile = preload("res://src/Projectile.tscn")
const Dust = preload("res://src/effects/Dust.tscn")
const PixelDust = preload("res://src/effects/PixelDust.tscn")
const GunSmoke = preload("res://src/effects/GunSmoke.tscn")
const PlayerShadow = preload("res://src/PlayerShadow.tscn")
const PlayerDeath = preload("res://src/player/PlayerDeath.tscn")
const Outro = preload("res://src/menus/Outro.tscn")

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
export(int) var DAMAGED_HEIGHT = -30
export(bool) var disable_knockback = false
export(float) var initial_fuel = 1.0
export(Texture) var player_flame = null
export(Texture) var tiny_player_flame = null
export(float) var COYOTE_TIME_BUFFER = 0.2
export(bool) var show_debug_states = false

enum State { IDLE, WALK, JUMP, FALL, DASH, JET_PACK, DEATH, DAMAGED, CROUCH }

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
var is_dead = false
var allow_land_animation = false
var can_be_damaged = true
var is_tiny_boost = false
var is_climber_boost = false
var is_big_boost = false
var is_level_switch_jump = false
var is_respawning = false
var is_frozen = false

func _ready():
	current_fuel = initial_fuel

func show_player():
	show()
	is_respawning = false

func freeze_player():
	is_frozen = true

func unfreeze_player():
	is_frozen = false

func play_eat_sound():
	AudioManager.play_sfx("PlayerAte")

func equip_gun():
	$AnimationPlayer.play("equip_gun")

func equip_boots():
	$AnimationPlayer.play("equip_boots")

func _process(delta):
	if Input.is_action_just_pressed("ui_gun"):
		Globals.HasGun = true
	if Input.is_action_just_pressed("ui_jetpack"):
		Globals.HasJetPack = true

func set_flipped(flipped):
	$Sprite.flip_h = flipped
	$ShootSprite.flip_h = flipped
	$SpriteWithBoots.flip_h = flipped
	$ShootSpriteWithBoots.flip_h = flipped

func _physics_process(delta):
	Globals.PlayerPosition = global_position
	if is_respawning or is_frozen or is_dead:
		return
	input.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	Globals.CameraOffsetY = 0
	if !is_dead:
		$PlayerArea/CollisionShape2D.set_deferred("disabled", !$PlayerArea/CollisionShape2D.disabled)
	if input.x < 0:
		$Sprite.flip_h = true
		$ShootSprite.flip_h = true
		$SpriteWithBoots.flip_h = true
		$ShootSpriteWithBoots.flip_h = true
	elif input.x > 0:
		$Sprite.flip_h = false
		$ShootSprite.flip_h = false
		$SpriteWithBoots.flip_h = false
		$ShootSpriteWithBoots.flip_h = false
	match current_state:
		State.IDLE:
			handle_idle(delta)
		State.WALK:
			handle_walk(delta)
		State.JUMP:
			handle_jump(delta)
		State.FALL:
			handle_fall(delta)
		State.JET_PACK:
			handle_jet_pack(delta)
		State.DEATH:
			handle_death(delta)
		State.DAMAGED:
			handle_damaged(delta)
		State.CROUCH:
			handle_crouch(delta)
	if Globals.HasJetPack and ($Sprite.visible or $ShootSprite.visible):
		$Sprite.hide()
		$SpriteWithBoots.hide()
		$SpriteWithBoots.show()
		$ShootSpriteWithBoots.hide()
	if Input.is_action_pressed("ui_shoot") and can_shoot and Globals.HasGun:
		if Globals.HasJetPack:
			$ShootSpriteWithBoots.show()
		else:
			$ShootSprite.show()
		can_shoot = false
		$ShotCooldownTimer.start()
		fire_projectile(position)
	if $ShotCooldownTimer.is_stopped() and $ShootSprite.visible:
		$ShootSprite.hide()
	if $ShotCooldownTimer.is_stopped() and $ShootSpriteWithBoots.visible:
		$ShootSpriteWithBoots.hide()
	if is_on_floor() and current_fuel < initial_fuel:
		current_fuel = initial_fuel
	if is_on_floor():
		can_jump = true
	if Input.is_action_just_pressed("ui_restart") and !is_dead:
		change_state(State.DEATH)
	knockback = lerp(knockback, Vector2.ZERO, 10 * delta)
	jump_buffer_count -= delta

func handle_damaged(delta):
	if init:
		$DamagedAnimation.play("damage")
		$AnimationPlayer.play("damaged")
		init = false
		is_tiny_boost = true
		change_state(State.JUMP)

func handle_death(delta):
	if init:
		AudioManager.play_sfx("PlayerDied")
		is_dead = true
		init = false
		if HUD.current_health > 0:
			HUD.set_health(0)
		$CollisionShape2D.set_deferred("disabled", true)
		$AnimationPlayer.play("death")

func spawn_player_death():
	var player_death = PlayerDeath.instance()
	get_parent().add_child(player_death)
	player_death.position = position

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
		if !is_on_floor():
			change_state(State.FALL)
		else:
			change_state(State.IDLE)
	elif Input.is_action_just_released("ui_jump"):
		change_state(State.FALL)
	var adjusted_input = input
	if Input.is_action_pressed("ui_lock"):
		adjusted_input = Vector2.ZERO
	velocity.x = lerp(velocity.x, knockback.x + adjusted_input.x * WALK_SPEED, WALK_ACCELERATION * delta)
	velocity.y = max(TERMINAL_JET_PACK_VELOCITY, lerp(velocity.y, knockback.y + velocity.y + JET_PACK_GRAVITY * delta, JET_PACK_ACCELERATION * delta))
	move_and_slide(velocity, Vector2.UP)

func handle_dash(delta):
	pass
#	if init:
#		time_passed = 0.0
#		next_shadow = shadow_increment
##		modulate.a = 0.0
#		can_dash = false
#		init = false
#		old_walk_speed = WALK_SPEED
#		old_walk_acceleration = WALK_ACCELERATION
#		old_fall_acceleration = FALL_ACCELERATION
#		velocity.y = JUMP_HEIGHT
#		spawn_shadow()
##		$ShadowTimer.start()
#		WALK_SPEED = old_walk_speed + 75
#		WALK_ACCELERATION = old_walk_acceleration + 25
#	time_passed += delta
#	if time_passed >= next_shadow:
#		spawn_shadow()
#		next_shadow += shadow_increment
#	if velocity.y >= 0:
##		modulate.a = 1.0
##		$ShadowTimer.stop()
#		change_state(State.FALL)
#	var adjusted_input = input
#	if Input.is_action_pressed("ui_lock"):
#		adjusted_input = Vector2.ZERO
#	WALK_SPEED = lerp(WALK_SPEED, old_walk_speed, 1 * delta)
#	WALK_ACCELERATION = lerp(WALK_ACCELERATION, old_walk_acceleration, 25 * delta)
#	FALL_ACCELERATION = lerp(FALL_ACCELERATION, old_fall_acceleration + 15, 20 * delta)
#	velocity.x = lerp(velocity.x, knockback.x + adjusted_input.x * WALK_SPEED, WALK_ACCELERATION * delta)
#	velocity.y = min(0, lerp(velocity.y, knockback.y + velocity.y + GRAVITY * delta, FALL_ACCELERATION * delta))
#	move_and_slide(velocity, Vector2.UP)

func spawn_shadow():
#	var tiny_shadow = PlayerShadow.instance()
#	get_parent().get_parent().find_node("Shadows").add_child(tiny_shadow)
#	tiny_shadow.position = position + Vector2(0, 12)
#	tiny_shadow.texture = tiny_player_flame
	
	var next_shadow = PlayerShadow.instance()
	get_parent().get_parent().find_node("Shadows").add_child(next_shadow)
	next_shadow.position = position + Vector2(0, 10)
	next_shadow.texture = player_flame

func fire_projectile(starting_position):
#	$AnimationPlayer.play("shoot")
	AudioManager.play_sfx("PlayerShot")
	var next_projectile = Projectile.instance()
	get_parent().get_parent().find_node("Projectiles").add_child(next_projectile)
	next_projectile.projectile_spawn_count = 0
	var projectile_distance_from_player = 6
	var shot_offset = Vector2(0, -4)
	if input == Vector2.ZERO:
		if $Sprite.flip_h:
			next_projectile.position = shot_offset + starting_position + Vector2.LEFT * projectile_distance_from_player
			next_projectile.set_direction(Vector2.LEFT)
		else:
			next_projectile.position = shot_offset + starting_position + Vector2.RIGHT * projectile_distance_from_player
			next_projectile.set_direction(Vector2.RIGHT)
	else:
		var adjusted_input = input
		if input.x < 0 and input.y != 0:
			adjusted_input = Vector2.LEFT
		elif input.x > 0 and input.y != 0:
			adjusted_input = Vector2.RIGHT
		next_projectile.position = starting_position + adjusted_input.normalized() * projectile_distance_from_player
		next_projectile.set_direction(adjusted_input.normalized())
	
	if Globals.HasBlueBullet:
		next_projectile.set_blue_bullet()
	
#	spawn_gunsmoke(next_projectile.position)
#	var knockback_amount = 32
#	if input.y > 0:
#		knockback_amount = 100
##		velocity.y = -100
#	knockback = next_projectile.direction.rotated(PI) * knockback_amount
#	if disable_knockback:
#		knockback = Vector2.ZERO

func spawn_gunsmoke(pos):
	var next_smoke = GunSmoke.instance()
	get_parent().add_child(next_smoke)
	next_smoke.position = pos

func spawn_dust():
	var next_dust = PixelDust.instance()
	get_parent().add_child(next_dust)
	next_dust.position = position + Vector2(0, 4)

func handle_idle(delta):
	if init:
		init = false
		velocity.y = 5
		if previous_state != State.FALL:
			$AnimationPlayer.play("idle")
		if previous_state == State.FALL:
			spawn_dust()
	if !is_on_floor():
		change_state(State.FALL)
	elif Input.is_action_just_pressed("ui_jump"):
		change_state(State.JUMP)
	elif input.x != 0:
		change_state(State.WALK)
	elif input.y == 1:
		change_state(State.CROUCH)
	var adjusted_input = input
	if Input.is_action_pressed("ui_lock"):
		adjusted_input = Vector2.ZERO
#	velocity.y = min(TERMINAL_VELOCITY, lerp(velocity.y, knockback.y + velocity.y + GRAVITY * delta, FALL_ACCELERATION * delta))
	velocity.x = lerp(velocity.x, knockback.x + adjusted_input.x * WALK_SPEED, WALK_DECELERATION * delta)
	move_and_slide(velocity, Vector2.UP)

func handle_crouch(delta):
	if init:
		init = false
		$AnimationPlayer.play("crouch_down")
		velocity.x = 0
	if !is_on_floor():
		change_state(State.FALL)
	elif Input.is_action_just_pressed("ui_jump"):
		change_state(State.JUMP)
	elif input.x != 0:
		change_state(State.WALK)
	elif input.y != 1:
		$AnimationPlayer.play("crouch_up")
		yield($AnimationPlayer, "animation_finished")
		change_state(State.IDLE)
	Globals.CameraOffsetY = input.y * 48
	move_and_slide(velocity, Vector2.UP)

func handle_walk(delta):
	if init:
		velocity.y = 5
		init = false
		if previous_state != State.FALL:
			$AnimationPlayer.play("walk")
		if previous_state == State.FALL:
			spawn_dust()
	if !is_on_floor():
		change_state(State.FALL)
	elif Input.is_action_just_pressed("ui_jump"):
		change_state(State.JUMP)
	elif input.x == 0:
		change_state(State.IDLE)
	var adjusted_input = input
	if Input.is_action_pressed("ui_lock"):
		adjusted_input = Vector2.ZERO
	velocity.x = lerp(velocity.x, knockback.x + adjusted_input.x * WALK_SPEED, WALK_ACCELERATION * delta)
	move_and_slide(velocity, Vector2.UP)

var temp_walk_speed = 0
var temp_walk_acceleration = 0
var temp_fall_acceleration = 0
var was_mushroom_boosted = false
func handle_jump(delta):
	if init:
		can_jump = false
		was_mushroom_boosted = false
		if previous_state == State.DAMAGED:
			$AnimationPlayer.play("damaged")
		else:
			$AnimationPlayer.play("jump_start")
		init = false
		if is_climber_boost:
			velocity.y = JUMP_HEIGHT * .85
		elif is_tiny_boost:
			velocity.y = JUMP_HEIGHT * .67
		elif is_big_boost:
			was_mushroom_boosted = true
			velocity.y = JUMP_HEIGHT * 1.33
		else:
			velocity.y = JUMP_HEIGHT
		is_tiny_boost = false
		is_big_boost = false
		is_climber_boost = false
		is_level_switch_jump = false
		temp_walk_speed = WALK_SPEED + 30
		temp_walk_acceleration = WALK_ACCELERATION + 5
	if velocity.y >= -50:
		$AnimationPlayer.play("jump_peak")
	if velocity.y >= 0:
		change_state(State.FALL)
	elif is_on_ceiling():
		velocity.y = -25
		change_state(State.FALL)
	elif Input.is_action_just_pressed("ui_jump") and current_fuel > 0 and Globals.HasJetPack:
		change_state(State.JET_PACK)
	elif Input.is_action_just_released("ui_jump") and !was_mushroom_boosted:
		$Tween.interpolate_property(self, "velocity", velocity, Vector2(velocity.x, velocity.y / 4.0), 0.05, Tween.TRANS_QUAD, Tween.EASE_OUT)
		$Tween.start()
		yield($Tween, "tween_all_completed")
		if current_state == State.JUMP:
			change_state(State.FALL)
	var adjusted_input = input
	if Input.is_action_pressed("ui_lock"):
		adjusted_input = Vector2.ZERO
	temp_walk_speed = lerp(temp_walk_speed, WALK_SPEED, 5 * delta)
	temp_walk_acceleration = lerp(temp_walk_acceleration, WALK_ACCELERATION, 5 * delta)
	temp_fall_acceleration = lerp(temp_fall_acceleration, FALL_ACCELERATION + 15, 20 * delta)
	velocity.x = lerp(velocity.x, knockback.x + adjusted_input.x * temp_walk_speed, temp_walk_acceleration * delta)
	velocity.y = min(0, lerp(velocity.y, knockback.y + velocity.y + GRAVITY * delta, temp_fall_acceleration * delta))
	move_and_slide(velocity, Vector2.UP)

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
		elif input.x == 0:
			if allow_land_animation:
				$AnimationPlayer.play("land")
			else:
				$AnimationPlayer.play("idle")
			if $PlayerLandedSoundTimer.is_stopped():
				AudioManager.play_sfx("PlayerLanded")
			change_state(State.IDLE)
		else:
			if allow_land_animation:
				$AnimationPlayer.play("short_land")
			else:
				$AnimationPlayer.play("walk")
			if $PlayerLandedSoundTimer.is_stopped():
				AudioManager.play_sfx("PlayerLanded")
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
	if show_debug_states:
		print("Changing state from %s to %s" % [get_state_name(current_state), get_state_name(next_state)])
	previous_state = current_state
	current_state = next_state
	
	if !is_level_switch_jump and next_state == State.JUMP and !is_big_boost and !is_tiny_boost and !is_climber_boost:
		AudioManager.play_sfx("PlayerJumped")

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
		State.DAMAGED:
			return "DAMAGED"

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
	elif anim_name == "death":
		Helpers.player_died()
		queue_free()
	elif anim_name == "eat_burger":
		TransitionScreen.transition_to(Outro)

func _on_PlayerArea_body_entered(body):
	if "TileMap" in body.name:
		var tiles = []
		var positions = []
		tiles.push_back(get_tree().current_scene.get_tile_name_at_position($FloorPosition.global_position))
		positions.push_back($FloorPosition.global_position)
		tiles.push_back(get_tree().current_scene.get_tile_name_at_position($RightPosition.global_position))
		positions.push_back($RightPosition.global_position)
		tiles.push_back(get_tree().current_scene.get_tile_name_at_position($LeftPosition.global_position))
		positions.push_back($LeftPosition.global_position)
		tiles.push_back(get_tree().current_scene.get_tile_name_at_position($TopPosition.global_position))
		positions.push_back($TopPosition.global_position)
		for i in range(0, len(tiles)):
			var tile = tiles[i]
			var pos = positions[i]
			if tile == "Lava":
				die()
#			elif tile == "SaveIdle":
#				print("Saved!")
#				get_tree().current_scene.set_tile_at_position(pos, "SaveActive")
#				Globals.SaveLevel = get_tree().current_scene.name
#				Globals.SaveCoordinates = get_tree().current_scene.get_world_to_map(pos)
			elif tile == "LevelNumbers":
				var level_number = get_tree().current_scene.get_level_number_from_position(pos)
				if level_number > 0:
					Globals.PlayerDirection = get_tree().current_scene.get_direction(global_position)
					Globals.PlayerPosition = global_position
					Globals.PlayerFlippedH = $Sprite.flip_h
					Helpers.change_level(level_number)

func heal_animation():
	$HealAnimation.play("healed")

func take_damage():
	if !can_be_damaged:
		return
	can_be_damaged = false
	HUD.decrement_health()
	if HUD.current_health <= 0:
		die()
	else:
		AudioManager.play_sfx("PlayerHurt")
		change_state(State.DAMAGED)

func climber_boost():
	is_climber_boost = true
	take_damage()

func die():
	if !is_dead:
		HUD.set_health(0)
		change_state(State.DEATH)

func big_boost():
	is_big_boost = true
	change_state(State.JUMP)

func tiny_boost():
	is_tiny_boost = true
	change_state(State.JUMP)

func _on_SpawnLandTimer_timeout():
	allow_land_animation = true

func _on_DamagedAnimation_animation_finished(anim_name):
	if anim_name == "damage":
		can_be_damaged = true
		$CollisionShape2D.set_deferred("disabled", true)
		$CollisionShape2D.set_deferred("disabled", false)

func eat_burger():
	$AnimationPlayer.play("eat_burger")

func _on_CheckForDeathTimer_timeout():
	if HUD.current_health <= 0 and current_state != State.DEATH and !is_dead:
		die()

func _on_PlayerLandedSoundTimer_timeout():
	pass # Replace with function body.
