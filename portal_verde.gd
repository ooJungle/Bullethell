extends Area2D

@export var id_da_fase: String = "Fase_plat" 
const cena_destino = "res://Cenas/Fases/Fase_plat.tscn"

func _ready():
	if cena_destino != "":
		ResourceLoader.load_threaded_request(cena_destino)
	if Global.portais_ativos.has(id_da_fase):
		if Global.portais_ativos[id_da_fase] == false:
			queue_free()

func _on_body_entered(body):
	var status = ResourceLoader.load_threaded_get_status(cena_destino)
	if body.is_in_group("players"):
		body.pode_se_mexer = false
		Transicao.transition()
		await Transicao.on_transition_finished
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var nova_cena = ResourceLoader.load_threaded_get(cena_destino)
			get_tree().change_scene_to_packed(nova_cena)
		
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var nova_cena = ResourceLoader.load_threaded_get(cena_destino) 
			get_tree().change_scene_to_packed(nova_cena)
			
		else:
			get_tree().change_scene_to_file(cena_destino)
