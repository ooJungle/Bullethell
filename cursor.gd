extends CharacterBody2D

@export var velocidade: float = 200.0
@export var raio_da_roda: float = 150.0

func _physics_process(delta: float):
	var direcao = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direcao * velocidade
	move_and_slide()

	if global_position.length() > raio_da_roda:
		global_position = global_position.limit_length(raio_da_roda)
