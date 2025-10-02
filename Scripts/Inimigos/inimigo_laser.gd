extends CharacterBody2D

# --- Variáveis de Movimento e Percepção ---
@export var velocidade = 150.0
@export var forca_maxima_direcao = 200.0
@export var tempo_percepcao = 0.5

# --- Variáveis de Combate e Estados ---
@export var player: Node2D
@export var forca_knockback = 600.0
@export_group("Timers do Ataque")
@export var duracaoMira: float = 2.0
@export var ducacaoLock: float = 0.5
@export var duracaoTiro: float = 1.0
@export var tiroCooldown: float = 6.0

# --- Nós Filhos ---
@onready var sprite: Sprite2D = $Inimigo
@onready var fire_point: Node2D = $FirePoint
@onready var linha: Line2D = $FirePoint/linha
@onready var linha_2: Line2D = $FirePoint/linha2
@onready var laserbeam: Sprite2D = $FirePoint/Laserbeam
@onready var ray_cast_2d: RayCast2D = $FirePoint/RayCast2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var perception_timer: Timer = $PerceptionTimer
@onready var collision_area: Area2D = $CollisionArea

# --- Máquina de Estados (FSM) ---
enum Estado { IDLE, MIRANDO, LOCKADO, ATIRANDO, COOLDOWN }
var estadoAtual = Estado.IDLE
var state_timer: float = 0.0
var locked_angle: float = 0.0
var alvo_atingido_neste_tiro: bool = false

# --- Variáveis de Estado de Knockback ---
var knockback = false
var tempo_knockback_atual = 0.0

func _ready() -> void:
	add_to_group("enemies")
	
	# Configura e conecta o timer de percepção para o pathfinding
	perception_timer.wait_time = tempo_percepcao
	perception_timer.timeout.connect(recalcular_caminho)
	
	mudar_para_estado(Estado.COOLDOWN) # Inicia a máquina de estados

# ================================================================
# --- LÓGICA DE MOVIMENTO (PHYSICS) ---
# ================================================================
func _physics_process(delta: float) -> void:
	if Global.paused:
		return

	# --- LÓGICA DE KNOCKBACK (Prioridade máxima) ---
	if knockback:
		tempo_knockback_atual += delta
		if tempo_knockback_atual >= 0.3:
			knockback = false
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
		move_and_slide()
		return

	# --- LÓGICA DE MOVIMENTO E ORIENTAÇÃO BASEADA EM ESTADO ---
	var direction_to_player = Vector2.ZERO
	if is_instance_valid(player):
		direction_to_player = (player.global_position - global_position).normalized()
	
	# O sprite principal sempre se orienta, exceto quando está travado e atirando
	if estadoAtual in [Estado.IDLE, Estado.COOLDOWN, Estado.MIRANDO]:
		# O "+ PI / 2" corrige a rotação se seu sprite aponta para "cima" por padrão
		sprite.rotation = direction_to_player.angle() + PI / 2

	# O inimigo SÓ SE MOVE durante IDLE ou COOLDOWN
	if estadoAtual in [Estado.IDLE, Estado.COOLDOWN]:
		var direcao_alvo = Vector2.ZERO
		if not navigation_agent.is_navigation_finished():
			direcao_alvo = global_position.direction_to(navigation_agent.get_next_path_position())

		if direcao_alvo.length() > 0:
			var velocidade_desejada = direcao_alvo * velocidade
			var forca_direcao = velocidade_desejada - velocity
			forca_direcao = forca_direcao.limit_length(forca_maxima_direcao)
			velocity += forca_direcao * delta
			velocity = velocity.limit_length(velocidade)
		else:
			velocity = velocity.lerp(Vector2.ZERO, delta * 3.0)
	else:
		# Nos outros estados (MIRANDO, LOCKADO, ATIRANDO), ele para.
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
	
	move_and_slide()

# ================================================================
# --- LÓGICA DA MÁQUINA DE ESTADOS (PROCESS) ---
# ================================================================
func _process(delta: float) -> void:
	if Global.paused:
		return
	
	# A lógica de estados roda separadamente da física
	match estadoAtual:
		Estado.IDLE:
			pass # Estado ocioso, poderia decidir iniciar um ataque aqui
		Estado.MIRANDO:
			modo_mira(delta)
		Estado.LOCKADO:
			modo_lockado(delta)
		Estado.ATIRANDO:
			modo_atirando(delta)
		Estado.COOLDOWN:
			modo_cooldown(delta)

# ================================================================
# --- FUNÇÕES DA MÁQUINA DE ESTADOS (Sua lógica original, intacta) ---
# ================================================================
func mudar_para_estado(novoEstado: Estado):
	estadoAtual = novoEstado
	linha.visible = false
	linha_2.visible = false
	laserbeam.visible = false
	
	match novoEstado:
		Estado.MIRANDO:
			state_timer = duracaoMira
			linha.visible = true
			linha_2.visible = true
			linha.default_color = Color("ffd900dc")
			linha_2.default_color = Color("ffd900dc")
		Estado.LOCKADO:
			state_timer = ducacaoLock
			linha.visible = true
			linha_2.visible = true
			linha.default_color = Color("ff7b00")
			linha_2.default_color = Color("ff7b00")
		Estado.ATIRANDO:
			state_timer = duracaoTiro
			laserbeam.visible = true
			alvo_atingido_neste_tiro = false
		Estado.COOLDOWN:
			state_timer = randf_range(0.0, tiroCooldown)
			recalcular_caminho() # Aproveita para calcular um novo caminho
		Estado.IDLE:
			mudar_para_estado(Estado.COOLDOWN)
	
func modo_mira(delta: float):
	if is_instance_valid(player):
		var direcao_do_player = player.global_position - fire_point.global_position
		fire_point.rotation = direcao_do_player.angle()
	
	state_timer -= delta
	if state_timer <= 0:
		locked_angle = fire_point.rotation
		mudar_para_estado(Estado.LOCKADO)

func modo_lockado(delta: float):
	fire_point.rotation = locked_angle
	state_timer -= delta
	if state_timer <= 0:
		mudar_para_estado(Estado.ATIRANDO)
		
func modo_atirando(delta: float):
	fire_point.rotation = locked_angle
	if not alvo_atingido_neste_tiro:
		ray_cast_2d.force_raycast_update()
		if ray_cast_2d.is_colliding():
			var collider = ray_cast_2d.get_collider()
			if collider == player:
				# Assumindo que você tem essas funções no seu singleton Global
				Global.vida -= 40
				Global.Tomou_ano() 
				alvo_atingido_neste_tiro = true
	
	state_timer -= delta
	if state_timer <= 0:
		mudar_para_estado(Estado.COOLDOWN)

func modo_cooldown(delta: float):
	state_timer -= delta
	if state_timer <= 0:
		mudar_para_estado(Estado.MIRANDO)

# ================================================================
# --- FUNÇÕES DE SUPORTE (Pathfinding e Knockback) ---
# ================================================================
func recalcular_caminho() -> void:
	# Só calcula um novo caminho se o inimigo estiver em um estado que permite movimento
	if is_instance_valid(player) and estadoAtual in [Estado.IDLE, Estado.COOLDOWN]:
		navigation_agent.target_position = player.global_position

func aplicar_knockback(direcao: Vector2):
	knockback = true
	tempo_knockback_atual = 0.0
	velocity = direcao * forca_knockback
	
	# --- INTERRUPÇÃO DE ATAQUE ---
	# Se o inimigo tomar dano, ele interrompe o que estava fazendo e entra em cooldown.
	if estadoAtual in [Estado.MIRANDO, Estado.LOCKADO, Estado.ATIRANDO]:
		mudar_para_estado(Estado.COOLDOWN)

# --- SINAL DE COLISÃO PARA KNOCKBACK ---
func _on_collision_area_body_entered(body: Node2D) -> void:
	if knockback or body == self:
		return
	if body.is_in_group("players"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)
