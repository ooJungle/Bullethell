extends Sprite2D

@onready var seta: Sprite2D = $"."

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()
	if Global.is_in_menu:
		seta.visible = true
	else:
		seta.visible = false
