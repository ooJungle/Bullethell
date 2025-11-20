extends Area2D

@export var id_da_fase: String = "fase_espaco" 
@export var cena_para_carregar: String = "res://Cenas/Fases/Fase_espaco.tscn"

func _ready():
	if Global.portais_ativos.has(id_da_fase):
		if Global.portais_ativos[id_da_fase] == false:
			queue_free()

func _on_body_entered(body):
	if body.is_in_group("players"):
		call_deferred("trocar_cena")

func trocar_cena():
	get_tree().change_scene_to_file(cena_para_carregar)
