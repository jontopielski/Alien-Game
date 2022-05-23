extends Area2D

func _ready():
	if Globals.HasJetPack:
		queue_free()

func _on_JetpackUpgrade_body_entered(body):
	if "Player" in body.name:
		Globals.HasJetPack = true
		AudioManager.play_sfx("Upgrade")
		queue_free()
