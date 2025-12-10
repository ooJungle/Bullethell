extends Area2D
@onready var som: AudioStreamPlayer = $som

func _on_body_entered(body):
	if body.is_in_group("players"):
		body.pode_se_mexer = false
		som.play()
		Transicao.transition()
		await Transicao.on_transition_finished
		call_deferred("voltar_para_hub")

func voltar_para_hub():
	get_tree().change_scene_to_file("res://Cenas/Fases/fase_rpg_2.tscn")
