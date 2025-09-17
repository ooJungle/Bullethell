extends CharacterBody2D

@export var velocidade = 150.0
@export var player: Node2D
@export_group("Timers")
@export var duracaoMira: float = 2.0
@export var ducacaoLock: float = 0.5
@export var duracaoTiro: float = 1.0
@export var tiroCooldown: float = 6.0

@onready var sprite: Sprite2D = $Inimigo
@onready var fire_point: Node2D = $FirePoint
@onready var linha: Line2D = $FirePoint/linha
@onready var laserbeam: Sprite2D = $FirePoint/Laserbeam
@onready var ray_cast_2d: RayCast2D = $FirePoint/RayCast2D

enum Estado { IDLE, MIRANDO, LOCKADO, ATIRANDO, COOLDOWN }
var estadoAtual = Estado.IDLE

var state_timer: float = 0.0
var locked_angle: float = 0.0
var alvo_atingido_neste_tiro: bool = false

func _ready() -> void:
	mudar_para_estado(Estado.COOLDOWN)

func _physics_process(delta: float) -> void:
	if estadoAtual in [Estado.MIRANDO, Estado.LOCKADO, Estado.ATIRANDO]:
		velocity = Vector2.ZERO
	else:
		if is_instance_valid(player):
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * velocidade
	
	var nearby = get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("players")
	for other in nearby:
		if other == self:
			continue
		var dist = (other.global_position - global_position)
		if dist.length() <= 17:
			velocity -= dist.normalized() * 50
			
	move_and_slide()

func _process(delta: float) -> void:
	match estadoAtual:
		Estado.IDLE:
			pass
		Estado.MIRANDO:
			modo_mira(delta)
		Estado.LOCKADO:
			modo_lockado(delta)
		Estado.ATIRANDO:
			modo_atirando(delta)
		Estado.COOLDOWN:
			modo_cooldown(delta)
			
func mudar_para_estado(novoEstado: Estado):
	estadoAtual = novoEstado
	linha.visible = false
	laserbeam.visible = false
	
	match novoEstado:
		Estado.MIRANDO:
			state_timer = duracaoMira
			linha.visible = true
			linha.default_color = Color("ffd900dc")
			
		Estado.LOCKADO:
			state_timer = ducacaoLock
			linha.visible = true
			linha.default_color = Color("ff7b00")
			
		Estado.ATIRANDO:
			state_timer = duracaoTiro
			laserbeam.visible = true
			alvo_atingido_neste_tiro = false
			
		Estado.COOLDOWN:
			state_timer = randf_range(0.0, tiroCooldown)
			
		Estado.IDLE:
			mudar_para_estado(Estado.COOLDOWN)
	
func modo_mira(delta):
	if is_instance_valid(player):
		var direcao_do_player = player.global_position - fire_point.global_position
		fire_point.rotation = direcao_do_player.angle()
	
	state_timer -= delta
	if state_timer <= 0:
		locked_angle = fire_point.rotation
		mudar_para_estado(Estado.LOCKADO)

func modo_lockado(delta):
	fire_point.rotation = locked_angle
	state_timer -= delta
	if state_timer <= 0:
		mudar_para_estado(Estado.ATIRANDO)
		
func modo_atirando(delta):
	fire_point.rotation = locked_angle
	if not alvo_atingido_neste_tiro:
		ray_cast_2d.force_raycast_update()
		
		if ray_cast_2d.is_colliding():
			var collider = ray_cast_2d.get_collider()
			if collider == player:
				print("Player atingido")
				alvo_atingido_neste_tiro = true
	
	state_timer -= delta
	if state_timer <= 0:
		mudar_para_estado(Estado.COOLDOWN)

func modo_cooldown(delta):
	state_timer -= delta
	if state_timer <= 0:
		mudar_para_estado(Estado.MIRANDO)
