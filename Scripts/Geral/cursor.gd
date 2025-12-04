extends CharacterBody2D

@export var velocidade_cursor: float = 200.0
@export var raio_da_roda: float = 170.0
var tempo: float = 0.0

# --- CONFIGURAÇÃO: Quanto porcento muda a cada hit? ---
@export var passo_porcentagem: float = 10.0 

@onready var arcos_visuais = get_node_or_null("../ArcosDeOpcoes")
var tween_dano: Tween
var opcao_atual: Dictionary = {} 

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float):
	if tempo <= 2: tempo += delta
	
	var direcao = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direcao * velocidade_cursor
	move_and_slide()

	if position.length() > raio_da_roda:
		position = position.limit_length(raio_da_roda)
	
	if arcos_visuais:
		opcao_atual = arcos_visuais.detectar_opcao_no_mouse(global_position)

# --- FUNÇÃO TAKE DAMAGE ATUALIZADA ---
func take_damage(perda_velocidade: float, aumento_rotacao: float, direcao_mudanca: float):
	if tempo > 2:
		# Visual
		if tween_dano: tween_dano.kill()
		modulate = Color(2.5, 0.0, 0.0, 1.0)
		tween_dano = create_tween()
		tween_dano.tween_property(self, "modulate", Color.WHITE, 0.15).set_trans(Tween.TRANS_SINE)
		
		# Velocidade
		velocidade_cursor = max(50.0, velocidade_cursor - perda_velocidade)
		if velocidade_cursor > 300: velocidade_cursor = 300

		# Roda
		if arcos_visuais:
			arcos_visuais.velocidade_rotacao = max(0.1, arcos_visuais.velocidade_rotacao + aumento_rotacao)
			
			# --- LÓGICA DE PORCENTAGEM ---
			# 'direcao_mudanca' deve ser 1.0 (aumenta vermelho) ou -1.0 (diminui vermelho)
			var variacao_final = direcao_mudanca * passo_porcentagem
			
			# Chama a nova função que redistribui tudo
			# Índice 0 é o Vermelho (Agressivo)
			arcos_visuais.aplicar_mudanca_percentual(0, variacao_final)

# ... (resto igual: unhandled_input, confirmar_escolha) ...
