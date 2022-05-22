extends KinematicBody2D

const PlayerShadow = preload("res://src/PlayerShadow.tscn")
const EnemyDeath = preload("res://src/enemies/EnemyDeath.tscn")

enum State { IDLE, WALK, FALL, JUMP, SPAWN_FRIENDS, SMASH, CHARGE_RAM, RAM, DIZZY, CRY, DAMAGED, DEATH, PREJUMP  }

export(int) var SPEED = 50
export(int) var RAM_SPEED = 100
export(int) var ACCELERATION = 20
export(int) var JUMP_ACCELERATION = 20
export(int) var RAM_ACCELERATION = 15
export(int) var JUMP_GRAVITY = 500
export(int) var GRAVITY = 500
export(int) var JUMP_VELOCITY = -150
export(int) var TERMINAL_VELOCITY = 150
export(Array, State) var ATTACK_CYCLES = []

var init = false
var previous_state = 0
var velocity = Vector2.ZERO
var direction = Vector2.RIGHT
var current_state = State.IDLE
var current_attack_index = 0
var health = 3
var speed_boost = 1.0

export(bool) var show_debug_states = false
export(Texture) var one_eye_missing = null
export(Texture) var two_eyes_missing = null
export(Texture) var three_eyes_missing = null
export(Texture) var dead_mook = null

func _ready():
	set_attack_timer_based_on_current_attack()

func _process(delta):
	if Input.is_action_just_pressed("ui_kill_boss"):
		change_state(State.DEATH)

func _physics_process(delta):
	match current_state:
		State.IDLE:
			handle_idle(delta)
		State.FALL:
			handle_fall(delta)
		State.WALK:
			handle_walk(delta)
		State.JUMP:
			handle_jump(delta)
		State.CHARGE_RAM:
			handle_charge_ram(delta)
		State.RAM:
			handle_ram(delta)
		State.DIZZY:
			handle_dizzy(delta)
		State.DEATH:
			handle_death(delta)
		State.PREJUMP:
			handle_pre_jump(delta)
	if direction.x < 0:
		$Sprite.flip_h = false
		$Eyes.flip_h = false
	else:
		$Sprite.flip_h = true
		$Eyes.flip_h = true
	if current_state != State.DIZZY and current_state != State.RAM and current_state != State.JUMP and current_state != State.FALL and Globals.PlayerPosition.x < position.x and direction == Vector2.RIGHT and $ChangeDirectionTimer.is_stopped():
		direction = Vector2.LEFT
		$ChangeDirectionTimer.start()
	elif current_state != State.DIZZY and current_state != State.RAM and current_state != State.JUMP and current_state != State.FALL and Globals.PlayerPosition.x > position.x and direction == Vector2.LEFT and $ChangeDirectionTimer.is_stopped():
		direction = Vector2.RIGHT
		$ChangeDirectionTimer.start()

func handle_pre_jump(delta):
	if init:
		$PreJumpTimer.start()
		init = false
	velocity.x = lerp(velocity.x, 25 * -direction.x, 25 * delta)
	velocity.y = min(TERMINAL_VELOCITY, lerp(velocity.y, velocity.y + GRAVITY * delta, JUMP_ACCELERATION * delta))
	move_and_slide(velocity, Vector2.UP)

func handle_death(delta):
	if init:
		get_tree().call_group("level", "spawn_gun")
		init = false
		spawn_death()
		queue_free()

func handle_dizzy(delta):
	if init:
		AudioManager.play_sfx("BigEnemyLanded")
		init = false
		get_tree().call_group("level", "screenshake")
		$DizzyTimer.wait_time = 3
		$DizzyFlipTimer.wait_time = 2.5
		$DizzyTimer.start()
		$DizzyFlipTimer.start()
		$AnimationPlayer.play("dizzy")
		if direction == Vector2.RIGHT:
			direction = Vector2.LEFT
		else:
			direction = Vector2.RIGHT
		velocity.y = JUMP_VELOCITY / 2
		velocity.x = 50 * direction.x
	if velocity.y >= 0 and !$Sprite.flip_v and !$DizzyFlipTimer.is_stopped():
		set_sprite_flips(true)
		set_sprite_offsets_y(4)
	elif $DizzyFlipTimer.is_stopped() and $Sprite.flip_v and velocity.y >= 0:
		set_sprite_flips(false)
		set_sprite_offsets_y(-4)
	velocity.x = lerp(velocity.x, 0, 5 * delta)
	velocity.y = min(TERMINAL_VELOCITY, lerp(velocity.y, velocity.y + GRAVITY * delta, JUMP_ACCELERATION * delta))
	move_and_slide(velocity, Vector2.UP)
	if current_state != State.DIZZY:
		$Sprite.offset.x = 0
		$Eyes.offset.x = 0
		set_sprite_flips(false)
		set_sprite_offsets_y(-4)

func take_damage():
	health -= 1
	$DamageAnimation.play("take_damage")
	AudioManager.play_sfx("BigEnemyHurt")
	if !$DizzyFlipTimer.is_stopped():
		$DizzyFlipTimer.stop()
		$DizzyTimer.wait_time = 0.5
		$DizzyTimer.start()
		velocity.y = JUMP_VELOCITY / 3
		velocity.x = 0
	$Eyes.show()
	if health == 2:
		speed_boost = 1.1
		$Eyes.texture = one_eye_missing
	elif health == 1:
		speed_boost = 1.2
		$Eyes.texture = two_eyes_missing
	elif health <= 0:
		change_state(State.DEATH)

func spawn_shadow():
	var next_shadow = PlayerShadow.instance()
	get_parent().get_parent().find_node("Shadows").add_child(next_shadow)
	next_shadow.position = position + Vector2(0, 0)
	next_shadow.texture = $Sprite.texture
	next_shadow.hframes = $Sprite.hframes
	next_shadow.frame = $Sprite.frame
	next_shadow.set_playback_speed(1.0)

func set_sprite_flips(flip):
	$Sprite.flip_v = flip
	$Eyes.flip_v = flip

func set_sprite_offsets_y(y_offset):
	$Sprite.offset.y = y_offset
	$Eyes.offset.y = y_offset

func wobble_offset_x(offset):
	$Sprite.offset.x = offset
	$Eyes.offset.x = offset

func handle_charge_ram(delta):
	if init:
		init = false
		$AnimationPlayer.play("charge_ram")
		$ChangeAttackTimer.stop()
		velocity.x = 0
	velocity.y = min(TERMINAL_VELOCITY, lerp(velocity.y, velocity.y + GRAVITY * delta, ACCELERATION * delta))
	move_and_slide(velocity, Vector2.UP)

var charge_count = 0
var next_charge = .0
var charge_increment = .1
func handle_ram(delta):
	if init:
		init = false
		$ShadowTimer.start()
		spawn_shadow()
		$AnimationPlayer.play("ram")
		charge_count = 0
		next_charge = charge_increment
	charge_count += delta
	if charge_count > next_charge:
		next_charge += charge_increment
		AudioManager.play_sfx("BigEnemyCharges")
	velocity.x = lerp(velocity.x, direction.x * RAM_SPEED * speed_boost, RAM_ACCELERATION * delta)
	velocity.y = min(TERMINAL_VELOCITY, lerp(velocity.y, velocity.y + GRAVITY * delta, ACCELERATION * delta))
	var movement_vector = move_and_slide(velocity, Vector2.UP)
	if abs(movement_vector.x) < 5:
		$ShadowTimer.stop()
		change_state(State.DIZZY)

func handle_jump(delta):
	if init:
		init = false
		velocity.y = JUMP_VELOCITY
		AudioManager.play_sfx("BigEnemyJumped")
		$AnimationPlayer.play("jump")
	if velocity.y >= 0:
		change_state(State.FALL)
	velocity.x = lerp(velocity.x, direction.x * SPEED * speed_boost, JUMP_ACCELERATION * delta)
	velocity.y = min(TERMINAL_VELOCITY, lerp(velocity.y, velocity.y + JUMP_GRAVITY * delta, JUMP_ACCELERATION * delta))
	move_and_slide(velocity, Vector2.UP)

func handle_walk(delta):
	if init:
		init = false
		$AnimationPlayer.play("walk")
	if !is_on_floor():
		change_state(State.FALL)
	velocity.x = lerp(velocity.x, direction.x * SPEED * speed_boost, ACCELERATION * delta)
	velocity.y = min(TERMINAL_VELOCITY, lerp(velocity.y, velocity.y + GRAVITY * delta, ACCELERATION * delta))
	move_and_slide(velocity, Vector2.UP)

func handle_fall(delta):
	if init:
		init = false
	if is_on_floor():
		if previous_state == State.JUMP:
			velocity.x = 0
			AudioManager.play_sfx("BigEnemyLanded")
			get_tree().call_group("level", "screenshake")
		change_state(State.WALK)
	velocity.x = lerp(velocity.x, direction.x * SPEED * speed_boost, JUMP_ACCELERATION * delta)
	velocity.y = min(TERMINAL_VELOCITY, lerp(velocity.y, velocity.y + GRAVITY * delta, JUMP_ACCELERATION * delta))
	move_and_slide(velocity, Vector2.UP)

func spawn_death():
	var next_death = EnemyDeath.instance()
	get_parent().get_parent().find_node("EnemyDeaths").add_child(next_death)
	next_death.texture = dead_mook
	next_death.hframes = $Sprite.hframes
	next_death.frame = 1
	next_death.position = position

func handle_idle(delta):
	if init:
		$AnimationPlayer.play("idle")
		init = false
	if !is_on_floor():
		change_state(State.FALL)

func change_state(next_state):
	previous_state = current_state
	init = true
	if show_debug_states:
		print("Changing state from %s to %s" % [get_state_name(current_state), get_state_name(next_state)])
	current_state = next_state

func get_state_name(state):
	match state:
		State.IDLE:
			return "IDLE"
		State.WALK:
			return "WALK"
		State.FALL:
			return "FALL"
		State.CHARGE_RAM:
			return "CHARGE_RAM"
		State.RAM:
			return "RAM"
		State.DIZZY:
			return "DIZZY"

func set_attack_timer_based_on_current_attack():
	match ATTACK_CYCLES[current_attack_index]:
		State.PREJUMP:
			$ChangeAttackTimer.wait_time = 2.5
		State.JUMP:
			$ChangeAttackTimer.wait_time = 2.5
		State.CHARGE_RAM:
			$ChangeAttackTimer.wait_time = 3.5
		State.RAM:
			$ChangeAttackTimer.wait_time = 3.5
	$ChangeAttackTimer.start()

func _on_ChangeAttackTimer_timeout():
	change_state(ATTACK_CYCLES[current_attack_index])
	current_attack_index += 1
	if current_attack_index == len(ATTACK_CYCLES):
		current_attack_index = 0
	set_attack_timer_based_on_current_attack()

func _on_ChangeDirectionTimer_timeout():
	pass # Replace with function body.

func _on_Area2D_body_entered(body):
	if "Player" in body.name and !$DamageAnimation.is_playing():
		if current_state == State.DIZZY:
			body.tiny_boost()
			take_damage()
		else:
			body.take_damage()

func _on_Area2D_area_entered(area):
	if "FallingPlatform" in area.name:
		area.get_parent().fast_crumble()

func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"charge_ram":
			change_state(State.RAM)

func _on_DizzyTimer_timeout():
	$Sprite.offset.x = 0
	$Eyes.offset.x = 0
	set_sprite_flips(false)
	set_sprite_offsets_y(-4)
	change_state(State.WALK)
	$ChangeAttackTimer.start()

func _on_DizzyFlipTimer_timeout():
	velocity.y = JUMP_VELOCITY / 3
	velocity.x = 0

func _on_ShadowTimer_timeout():
	if current_state == State.RAM:
		spawn_shadow()
	else:
		$ShadowTimer.stop()

func _on_PreJumpTimer_timeout():
	change_state(State.JUMP)
