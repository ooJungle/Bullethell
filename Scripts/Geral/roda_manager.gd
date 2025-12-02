extends Node

# O sinal que avisa o NPC quando o minigame acabou
signal roda_finalizada(resultado) # resultado pode ser "venceu", "perdeu", etc.

# A cena da roda que criamos antes (RodaDeDialogo.tscn)
const CENA_RODA = preload("res://Cenas/Geral/roda_de_dialogo.tscn") # Ajuste o caminho!

var instancia_roda: Node2D = null

func iniciar_roda(_dificuldade: int = 1):
	if instancia_roda: return # Já tem uma rodando
	
	# 1. Cria a roda
	instancia_roda = CENA_RODA.instantiate()
	
	# 2. Adiciona numa CanvasLayer temporária
	var layer = CanvasLayer.new()
	layer.name = "CamadaRoda"
	layer.add_child(instancia_roda)
	get_tree().root.add_child(layer)
	
	# --- CORREÇÃO: CENTRALIZAR NA TELA ---
	# Pega o tamanho da janela do jogo (Viewport)
	var tamanho_tela = get_tree().get_root().get_visible_rect().size
	
	# Define a posição da roda para a metade da largura e metade da altura
	instancia_roda.global_position = tamanho_tela / 2
	# -------------------------------------
	
	# 3. Pausa o jogo principal
	get_tree().paused = true

func fechar_roda(resultado: String):
	if not instancia_roda: return
	
	# 1. Destroi a camada e a roda
	instancia_roda.get_parent().queue_free()
	instancia_roda = null
	
	# 2. Despausa o jogo
	get_tree().paused = false
	
	# 3. Avisa quem chamou (o NPC)
	roda_finalizada.emit(resultado)
