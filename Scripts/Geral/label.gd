extends Label
@onready var label: Label = $"."

func _physics_process(delta: float) -> void:
	label.text = str(Global.dano)
