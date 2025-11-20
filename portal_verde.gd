extends Area2D

# Export permite que você configure isso no Inspector para cada portal diferente
@export var id_da_fase: String = "fase_espaco" 
@export var cena_para_carregar: String = "res://Cenas/Fases/Fase_espaco.tscn"

func _ready():
	# Assim que a cena carrega, o portal pergunta ao Global:
	# "Eu ainda devo existir?"
	if Global.portais_ativos.has(id_da_fase):
		if Global.portais_ativos[id_da_fase] == false:
			queue_free() # Se for false, se deleta imediatamente

func _on_body_entered(body):
	if body.is_in_group("players"):
		# 1. Avisa o Global que este portal foi usado/destruído
		if Global.portais_ativos.has(id_da_fase):
			Global.portais_ativos[id_da_fase] = false
		
		# 2. Troca de cena
		call_deferred("trocar_cena")

func trocar_cena():
	get_tree().change_scene_to_file(cena_para_carregar)
