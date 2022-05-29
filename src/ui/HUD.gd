extends CanvasLayer

export(int) var current_health = 3
export(int) var max_health = 3

export(Texture) var full_heart = null
export(Texture) var empty_heart = null

onready var health_text = find_node("Count")

var time_start = 0

func _ready():
	update_health_text()
	update_health_icons()

func _process(delta):
	$UI/FPS.text = str(Engine.get_frames_per_second()) + " FPS"
	if Input.is_action_just_pressed("ui_screenshot") and OS.is_debug_build():
		var image = get_viewport().get_texture().get_data()
		image.flip_y()
		image.save_png("C:\\Users\\jonto\\Desktop\\Game_Screenshot_%s.png" % str(randi() % 1000))

func reset_health():
	current_health = max_health
	update_health_text()
	update_health_icons()

func update_health_icons():
	for heart in $UI/Hearts.get_children():
		heart.hide()
	for i in range(0, max_health):
		$UI/Hearts.get_child(i).show()
		if i < current_health:
			$UI/Hearts.get_child(i).texture = full_heart
		else:
			$UI/Hearts.get_child(i).texture = empty_heart

func set_health(health):
	current_health = health
	update_health_text()
	update_health_icons()

func decrement_health():
	set_health(current_health - 1)

func update_health_text():
	var show_health = max(0, current_health)
	health_text.text = "%d/%d" % [show_health, max_health]

func show_hud():
	$UI.show()

func hide_hud():
	$UI.hide()
