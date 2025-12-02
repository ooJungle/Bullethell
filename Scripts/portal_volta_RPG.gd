extends Area2D

func _on_body_entered(body):
	if body.is_in_group("players"):		
		call_deferred("voltar_para_hub")

func voltar_para_hub():
	get_tree().change_scene_to_file("res://Cenas/Fases/fase_rpg_2.tscn")
