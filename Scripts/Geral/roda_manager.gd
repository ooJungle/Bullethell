extends Node

signal roda_finalizada(resultado)

var instancia_roda: Node2D = null
var player_ref: CharacterBody2D = null 

# MUDANÇA: Agora recebe a CENA (PackedScene) em vez de array
func iniciar_roda_com_cena(cena_para_abrir: PackedScene):
	if instancia_roda or not cena_para_abrir: return
	
	# 1. Trava Player
	player_ref = get_tree().get_first_node_in_group("players")
	if player_ref:
		player_ref.pode_se_mexer = false
		player_ref.velocity = Vector2.ZERO 
		if player_ref.has_node("Hitbox/CollisionShape2D"):
			player_ref.get_node("Hitbox/CollisionShape2D").set_deferred("disabled", true)
	
	# 2. Instancia a cena que foi passada
	instancia_roda = cena_para_abrir.instantiate()
	
	# 3. Adiciona na Tela
	var layer = CanvasLayer.new()
	layer.name = "CamadaRoda"
	layer.add_child(instancia_roda)
	get_tree().root.add_child(layer)
	
	# 4. Centraliza
	var tamanho_tela = get_tree().get_root().get_visible_rect().size
	instancia_roda.global_position = tamanho_tela / 2 - Vector2(0, 2 * tamanho_tela.y/7)

func fechar_roda(resultado: String):
	if not instancia_roda: return
	
	instancia_roda.get_parent().queue_free()
	instancia_roda = null
	
	if player_ref:
		player_ref.pode_se_mexer = true
		if player_ref.has_node("Hitbox/CollisionShape2D"):
			player_ref.get_node("Hitbox/CollisionShape2D").set_deferred("disabled", false)
		player_ref = null 
	
	roda_finalizada.emit(resultado)
