extends CanvasLayer

export(int) var current_health = 3
export(int) var max_health = 3

onready var health_text = find_node("Count")

func _ready():
	update_health_text()

func reset_health():
	current_health = max_health
	update_health_text()

func set_health(health):
	current_health = health
	update_health_text()

func decrement_health():
	set_health(current_health - 1)

func update_health_text():
	var show_health = max(0, current_health)
	health_text.text = "%d/%d" % [show_health, max_health]
