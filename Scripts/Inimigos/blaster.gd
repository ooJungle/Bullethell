extends Node2D

# --- Variáveis de Combate e Estados ---
@export_group("Timers do Ataque")
@export var duracaoMira: float = 1.0   # Duração do aviso (linha)
@export var ducacaoLock: float = 0.3   # Duração do "lock" (mudança de cor)
@export var duracaoTiro: float = 0.9   # Duração do laser ativo

# --- Nós Filhos ---
@onready var fire_point: Node2D = $FirePoint
@onready var linha: Line2D = $FirePoint/linha
@onready var linha_2: Line2D = $FirePoint/linha2
@onready var laserbeam: Sprite2D = $FirePoint/Laserbeam
@onready var ray_cast_2d: RayCast2D = $FirePoint/RayCast2D

var player: CharacterBody2D

# --- Máquina de Estados (FSM) ---
enum Estado { MIRANDO, LOCKADO, ATIRANDO }
var estadoAtual = Estado.MIRANDO
var state_timer: float = 0.0
var alvo_atingido_neste_tiro: bool = false

func _ready() -> void:
	if linha:
		linha.points[1] = Vector2(5000, 0)
	if linha_2:
		linha_2.points[1] = Vector2(5000, 0)
		
	player = get_node_or_null("/root/Node2D/player")
	
	mudar_para_estado(Estado.MIRANDO)

func _process(delta: float) -> void:
	if Global.paused:
		return
	
	match estadoAtual:
		Estado.MIRANDO:
			modo_mira(delta)
		Estado.LOCKADO:
			modo_lockado(delta)
		Estado.ATIRANDO:
			modo_atirando(delta)

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
			# Cor de aviso inicial
			linha.default_color = Color("ffd900dc") 
			linha_2.default_color = Color("ffd900dc")
		Estado.LOCKADO:
			state_timer = ducacaoLock
			linha.visible = true
			linha_2.visible = true
			# Cor de aviso final (antes do tiro)
			linha.default_color = Color("ff7b00") 
			linha_2.default_color = Color("ff7b00")
		Estado.ATIRANDO:
			state_timer = duracaoTiro
			laserbeam.visible = true
			alvo_atingido_neste_tiro = false

func modo_mira(delta: float):
	# Não precisamos mais mirar, o spawner já rotacionou o BlasterFixo.
	# Apenas esperamos o timer.
	state_timer -= delta * Global.fator_tempo
	if state_timer <= 0:
		mudar_para_estado(Estado.LOCKADO)

func modo_lockado(delta: float):
	# Apenas esperamos o timer.
	state_timer -= delta * Global.fator_tempo
	if state_timer <= 0:
		mudar_para_estado(Estado.ATIRANDO)
		
func modo_atirando(delta: float):
	if not alvo_atingido_neste_tiro:
		ray_cast_2d.force_raycast_update()
		
		if ray_cast_2d.is_colliding():
			var collider = ray_cast_2d.get_collider()
			print("Colidiu com o nó: ", collider.name)
			print("Grupos deste nó: ", collider.get_groups())
			if is_instance_valid(collider) and collider.is_in_group("player"):
				player.take_damage(20)
				alvo_atingido_neste_tiro = true 
	
	state_timer -= delta * Global.fator_tempo
	if state_timer <= 0:
		queue_free()
