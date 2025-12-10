extends Area2D

@onready var audio: AudioStreamPlayer = $som

func _on_body_entered(body):
	body.pode_se_mexer = false
	audio.play()
	Transicao.transition()
	await Transicao.on_transition_finished
	if body.is_in_group("players"):
		call_deferred("voltar_para_hub")

func voltar_para_hub():
	get_tree().change_scene_to_file("res://Cenas/Fases/fase_espaco_2.tscn")
