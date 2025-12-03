extends Node

signal roda_finalizada(resultado)

# A cena da roda (RodaDeDialogo.tscn)
const CENA_RODA = preload("res://Cenas/Geral/roda_de_dialogo.tscn")

var instancia_roda: Node2D = null
var player_ref: CharacterBody2D = null # Guardamos a referência para destravar depois

func iniciar_roda(dificuldade: int = 1):
	if instancia_roda: return
	
	# 1. Encontra o Player para travá-lo
	player_ref = get_tree().get_first_node_in_group("players")
	if player_ref:
		player_ref.pode_se_mexer = false
		player_ref.velocity = Vector2.ZERO # Garante que ele pare imediatamente
		
		# DICA DE OURO: Torna o player invulnerável para não morrer conversando
		# (Desativa a colisão da Hitbox dele temporariamente)
		if player_ref.has_node("Hitbox/CollisionShape2D"):
			player_ref.get_node("Hitbox/CollisionShape2D").set_deferred("disabled", true)
	
	# 2. Cria a Roda
	instancia_roda = CENA_RODA.instantiate()
	
	# 3. Adiciona na CanvasLayer (Overlay)
	var layer = CanvasLayer.new()
	layer.name = "CamadaRoda"
	layer.add_child(instancia_roda)
	get_tree().root.add_child(layer)
	
	# 4. Centraliza a Roda na tela
	var tamanho_tela = get_tree().get_root().get_visible_rect().size
	instancia_roda.global_position = tamanho_tela / 2 - Vector2(0, 2 * tamanho_tela.y/7)
	
func fechar_roda(resultado: String):
	if not instancia_roda: return
	
	# 1. Destroi a roda
	instancia_roda.get_parent().queue_free()
	instancia_roda = null
	
	# 2. Destrava o Player
	if player_ref:
		player_ref.pode_se_mexer = true
		
		# Remove a invulnerabilidade
		if player_ref.has_node("Hitbox/CollisionShape2D"):
			player_ref.get_node("Hitbox/CollisionShape2D").set_deferred("disabled", false)
		
		player_ref = null # Limpa a referência
	
	# 3. Avisa o NPC
	roda_finalizada.emit(resultado)
