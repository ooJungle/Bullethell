extends CharacterBody2D

@export var speed = 50.0
@export var gravity_power = 10.0
@export var rotation_speed = 10.0 # Suavidade da rotação ao mudar de parede
@export var player_path: NodePath # Caminho para o nó do Jogador na cena principal

# O RayCast que detecta o chão
@onready var floor_raycast = $RayCast2D
@onready var player = get_node_or_null(player_path)

var current_speed = 0.0

func _ready():
	# Garante que o RayCast ignore o próprio corpo da lesma
	floor_raycast.add_exception(self)

func _physics_process(delta):
	# 1. Aplicar uma "gravidade local" (sempre puxando para baixo em relação à lesma)
	velocity.y += gravity_power * delta
	
	# 2. Lógica de detecção de superfície
	if floor_raycast.is_colliding():
		var normal = floor_raycast.get_collision_normal()
		
		# Se a normal da superfície for diferente da nossa rotação atual ("up" local), alinha
		if transform.y.angle_to(normal) != 0:
			# Cria um novo transform alinhado à normal
			var target_transform = align_with_y(global_transform, normal)
			
			# Interpola suavemente para evitar "pulos" bruscos nos cantos
			global_transform = global_transform.interpolate_with(target_transform, rotation_speed * delta)
	
	# 3. Perseguir o Jogador
	if player:
		# Calcula a direção global até o jogador
		var direction_to_player = global_position.direction_to(player.global_position)
		
		# Transforma essa direção para o espaço local da lesma
		# O eixo X local (transform.x) é a frente da lesma
		var local_direction = transform.x.dot(direction_to_player)
		
		# Se local_direction > 0, o jogador está à frente. < 0, está atrás.
		if local_direction > 0.1:
			current_speed = speed
		elif local_direction < -0.1:
			current_speed = -speed
		else:
			current_speed = 0
	else:
		# Se não achar o jogador, apenas anda para frente
		current_speed = speed

	# 4. Aplicar movimento no eixo X local da lesma
	# Convertemos a velocidade local X para velocidade global
	velocity = transform.x * current_speed
	
	move_and_slide()

# --- Função Auxiliar de Matemática ---
# Esta função mágica rotaciona a matriz do objeto para que o eixo Y aponte na direção da normal
func align_with_y(xform, new_y):
	xform.y = new_y
	xform.x = -new_y.orthogonal()
	return xform.orthonormalized()
