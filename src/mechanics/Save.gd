extends Area2D

var is_active = false
var coordinates = Vector2.ZERO

func _on_Save_body_entered(body):
	if "Player" in body.name:
		if HUD.current_health < HUD.max_health:
			get_tree().call_group("player", "heal_animation")
			HUD.set_health(HUD.max_health)
		if !is_active and !$AnimationPlayer.is_playing():
			save()

func respawn_player():
	$AnimationPlayer.play("respawn")

func save():
	Globals.HasSavedOnce = true
	get_tree().call_group("save", "deactivate")
	yield(get_tree().create_timer(0.1), "timeout")
	is_active = true
	$AnimationPlayer.play("activate")
	Globals.SaveLevel = get_tree().current_scene.name
	Globals.SaveCoordinates = get_tree().current_scene.get_world_to_map(position)

func deactivate():
	if is_active:
		is_active = false
		$AnimationPlayer.play("deactivate")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "activate":
		$AnimationPlayer.play("active")
	elif anim_name == "deacticate":
		$AnimationPlayer.play("inactive")
	elif anim_name == "respawn":
		$AnimationPlayer.play("active")
#		yield(get_tree().create_timer(0.01), "timeout")
		get_tree().call_group("player", "show_player")

func _on_CollisionResetTimer_timeout():
	$CollisionShape2D.set_deferred("disabled", true)
	$CollisionShape2D.set_deferred("disabled", false)
