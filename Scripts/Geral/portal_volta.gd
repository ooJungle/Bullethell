extends Area2D

@export var id_desta_fase: String = "fase_RPG"

func _on_body_entered(body):
	if body.is_in_group("players"):
		if Global.portais_ativos.has(id_desta_fase):
			Global.portais_ativos[id_desta_fase] = false
		
		call_deferred("voltar_para_hub")

func voltar_para_hub():
	get_tree().change_scene_to_file("res://Cenas/Fases/Fase_0.tscn")
