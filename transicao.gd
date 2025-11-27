extends CanvasLayer

signal on_transition_finished()
@onready var color_rect: ColorRect = $ColorRect
@onready var fade: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	color_rect.visible = false
	fade.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name):
	if anim_name == "fade_to_black" :
		on_transition_finished.emit()
		fade.play("fade_to_normal",-1, 1.5)
	elif anim_name == "fade_to_normal" :
		color_rect.visible = false
		
func transition():
	color_rect.visible = true 
	fade.play("fade_to_black",-1, 1.5)
