extends CharacterBody2D

# --- CONFIGURAÇÃO DE TEXTO ---
@export_group("Diálogos")
@export_multiline var falas_interacao_1: Array[String] = [
	"Olá, guerreiro. Está pronto para o desafio?",
	"Escolha com sabedoria quantos oponentes deseja enfrentar."
]

@export_multiline var falas_interacao_2: Array[String] = [
	"Você sobreviveu... impressionante.",
	"Deseja tentar a sorte novamente?"
]

@export_multiline var falas_interacao_final: Array[String] = [
	"Muito bem! Você provou seu valor.",
	"O caminho está livre para você."
]

# --- CONFIGURAÇÃO DA RODA ---
@export_group("Cenas da Roda")
@export var cena_fase_1: PackedScene
@export var cena_fase_2: PackedScene

# --- CONFIGURAÇÃO DO PORTAL ---
@export_group("Portal")
@export var portal_saida: Area2D 

# --- REFERÊNCIAS VISUAIS ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D 

# --- VARIÁVEIS INTERNAS ---
var interacao_atual: int = 0 
var player_na_area: bool = false
var pode_falar: bool = true
var inimigos_restantes: int = 0 
var memoria_quantidade: int = 0 

func _ready():
	if has_node("Area2D"):
		$Area2D.body_entered.connect(_on_area_entered)
		$Area2D.body_exited.connect(_on_area_exited)
	
	if Global.has_signal("inimigo_morreu"):
		Global.inimigo_morreu.connect(_on_inimigo_morreu)

	if sprite:
		sprite.play("idle")
		
	# Garante que o portal comece fechado
	if portal_saida and portal_saida.has_method("ativar_portal") == false:
		portal_saida.visible = false
		portal_saida.monitoring = false

func _process(_delta):
	# Inicia conversa apenas se não houver inimigos e não estiver falando
	if player_na_area and Input.is_action_just_pressed("interagir") and pode_falar and inimigos_restantes <= 0:
		if not Dialogo.is_active: 
			iniciar_conversa()

func iniciar_conversa():
	pode_falar = false
	print("Iniciando conversa. Fase da interação: ", interacao_atual)
	
	# --- FASE PÓS-JOGO (3+) ---
	# Se o jogador voltar aqui depois de tudo concluído
	if interacao_atual > 2:
		if sprite: sprite.play("falando")
		Dialogo.start_dialogue(["O portal já está aberto. Vá logo!", "Não há mais nada para fazer aqui."])
		await Dialogo.finished
		
		if sprite: sprite.play("idle")
		await get_tree().create_timer(0.3).timeout
		pode_falar = true
		return
	
	# --- EXIBE O DIÁLOGO DA VEZ (0, 1 ou 2) ---
	if sprite:
		sprite.play("falando")
	
	var texto_a_usar: Array[String] = []
	if interacao_atual == 0:
		texto_a_usar = falas_interacao_1
		Dialogo.tutorial = true
	elif interacao_atual == 1:
		texto_a_usar = falas_interacao_2
		Dialogo.tutorial = false
	else:
		texto_a_usar = falas_interacao_final # Texto final
		Dialogo.tutorial = false

	Dialogo.start_dialogue(texto_a_usar)
	await Dialogo.finished
	
	if sprite:
		sprite.play("idle")
		
	# --- FASE FINAL (2) - ABRE O PORTAL ---
	# Se chegamos aqui e a interação é 2 (seja por batalha ou por pular), abrimos o portal.
	if interacao_atual == 2:
		print("Finalizando quest. Abrindo portal.")
		ativar_portal_se_necessario()
		interacao_atual += 1 # Vai para 3 (Pós-jogo)
		
		await get_tree().create_timer(0.5).timeout
		pode_falar = true
		return # Encerra aqui, não abre roda.

	# --- FASE DE ESCOLHA (0 ou 1) ---
	var cena_para_abrir: PackedScene
	if interacao_atual == 0:
		cena_para_abrir = cena_fase_1
	else:
		cena_para_abrir = cena_fase_2
	
	if not cena_para_abrir:
		print("ERRO: Cena da roda não configurada!")
		pode_falar = true
		return
	
	RodaManager.iniciar_roda_com_cena(cena_para_abrir)
	
	var resultado = await RodaManager.roda_finalizada
	print("O Jogador escolheu na roda: ", resultado)
	
	# --- PROCESSA A ESCOLHA ---
	var quantidade_inimigos = 0
	
	# Limpeza da string: Remove "!", Espaços e põe em MAIÚSCULO para facilitar o match
	var resultado_limpo = resultado.replace("!", "").strip_edges().to_upper()
	
	match resultado_limpo:
		"20": 
			quantidade_inimigos = 20
			memoria_quantidade = 20
		"8":    
			quantidade_inimigos = 8
			memoria_quantidade = 8
		"3": 
			quantidade_inimigos = 3
			memoria_quantidade = 3
		"SIM":     
			quantidade_inimigos = memoria_quantidade 
		"NÃO", "NAO":     
			quantidade_inimigos = 0
		_:
			print("Opção desconhecida: ", resultado)
			quantidade_inimigos = 0
	
	inimigos_restantes = quantidade_inimigos
	
	if quantidade_inimigos > 0:
		# Batalha começa
		var fase_atual = get_tree().current_scene
		if fase_atual.has_method("spawnar_onda_por_escolha"):
			fase_atual.spawnar_onda_por_escolha(quantidade_inimigos)
	else:
		# Sem batalha (Escolheu NÃO ou ocorreu erro)
		if interacao_atual == 1:
			# Se pulou o Round 2, vamos direto para o final AGORA.
			print("Pulando batalha 2. Iniciando final imediatamente.")
			interacao_atual += 1 # Avança para 2
			
			# Chama a função de novo recursivamente (com await para garantir ordem)
			await iniciar_conversa()
			return
		else:
			# Caso genérico (ex: pulou a primeira luta por erro)
			avancar_interacao()

func _on_inimigo_morreu():
	if inimigos_restantes > 0:
		inimigos_restantes -= 1
		
		if inimigos_restantes <= 0:
			print("Vitória! Todos inimigos derrotados.")
			avancar_interacao()

func avancar_interacao():
	interacao_atual += 1 
	
	# Delay para o jogador respirar antes de poder falar de novo
	await get_tree().create_timer(0.5).timeout 
	pode_falar = true
	
	# NOTA: O portal só abrirá quando o jogador FALAR com o NPC novamente (interação 2),
	# pois é lá que está o texto final ("Muito bem!...") e o comando ativar_portal.

func ativar_portal_se_necessario():
	if portal_saida:
		# Verifica se tem o método ou se é apenas para setar visible
		if portal_saida.has_method("ativar_portal"):
			portal_saida.ativar_portal()
		else:
			# Fallback caso o script do portal seja simples
			portal_saida.visible = true
			portal_saida.monitoring = true
			print("Portal ativado (modo manual).")
	else:
		print("ERRO: O Portal de Saída não foi arrastado para o Inspector do NPC!")

func _on_area_entered(body):
	if body.is_in_group("players"): player_na_area = true

func _on_area_exited(body):
	if body.is_in_group("players"): player_na_area = false
