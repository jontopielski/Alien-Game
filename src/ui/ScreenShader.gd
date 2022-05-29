extends CanvasLayer

func show_normal_background():
	$BossBackground.hide()
	$Background.show()

func show_boss_background():
	$Background.hide()
	$BossBackground.show()
