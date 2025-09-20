extends CharacterBody2D

@export var speed: float = 300.0
@export var forca_salto_inimigo: float = 5.0 # Nova variável para a força do salto

@onready var sprite: AnimatedSprite2D = $sprite
var direction: Vector2 = Vector2.ZERO
var vida_maxima: int = 5
var vida: int = vida_maxima

func _ready() -> void:
	add_to_group("players")
	get_viewport().transparent_bg = true

func take_damage(amount: int) -> void:
	vida -= amount
	print("Player tomou dano. Vida:", vida)
	if vida <= 0:
		die()

func die() -> void:
	print("morreu")

func _physics_process(_delta: float) -> void:
	get_window().mouse_passthrough = false
	if Global.paused:
		return
	# Input
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	# Flip horizontal do sprite
	if direction.x > 0:
		sprite.flip_h = false
	elif direction.x < 0:
		sprite.flip_h = true

	# Movimento + animação
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed
		if sprite.animation != "Walking":
			sprite.play("Walking")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		if sprite.animation != "Idle":
			sprite.play("Idle")

	move_and_slide()
	
	handle_enemy_bounce() # Chamada para a nova função de verificação

# --- FUNÇÃO DE SALTO FORÇADO (CORRIGIDA) ---
func handle_enemy_bounce():
	# Primeiro, verificamos se o jogador está realmente no chão
	if is_on_floor():
		# Agora, iteramos por todas as colisões que aconteceram no último frame
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			# Verificamos se o corpo com que colidimos é um inimigo
			if collider and collider.is_in_group("enemies"):
				# Se estamos no chão E colidimos com um inimigo, assumimos que o inimigo é o chão.
				# Então, forçamos o salto.
				position.y -= forca_salto_inimigo
				# Encontrámos a colisão que queríamos, podemos parar o loop
				break

func _unhandled_input(event: InputEvent) -> void:
	# Verifica se a ação "ui_cancel" (ESC) foi recém-pressionada
	if event.is_action_pressed("ui_cancel"):
		if not Global.paused:
			$".."/PauseMenu.start_pause()
