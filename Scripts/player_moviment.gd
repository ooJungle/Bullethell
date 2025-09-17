extends CharacterBody2D

@export var speed: float = 300.0
@onready var sprite: AnimatedSprite2D = $sprite
var direction: Vector2 = Vector2.ZERO   # inicializado

func _ready() -> void:
	add_to_group("players")
	
var vida_maxima: int = 5
var vida: int = vida_maxima

func take_damage(amount: int) -> void:
	vida -= amount
	print("Player tomou dano. Vida:", vida)
	if vida <= 0:
		die()

func die() -> void:
	print("morreu")

func _physics_process(_delta: float) -> void:
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

func _unhandled_input(event: InputEvent) -> void:
	# Verifica se a ação "ui_cancel" (ESC) foi recém-pressionada
	if event.is_action_pressed("ui_cancel"):
		if not get_tree().paused and not $".."/PauseMenu/CanvasLayer/PauseVideo.is_playing():
			$".."/PauseMenu.start_pause()
		else:
			$".."/PauseMenu._on_pause_video_finished()
			$".."/PauseMenu._on_resume_button_pressed()
			get_tree().root.set_input_as_handled()
