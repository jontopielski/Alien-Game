extends Area2D

const Outro = preload("res://src/menus/Outro.tscn")

func _on_Burger_body_entered(body):
	if "Player" in body.name:
		queue_free()
		get_tree().call_group("player", "freeze_player")
		get_tree().call_group("player", "eat_burger")

