extends Node2D

@export var attack_sequence: Array[Dictionary] = [  # Defina padrões de ataques aqui
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
	{"type": "blaster_wave", "count": 4, "delay": 0.8, "pattern": "diagonal"},     # Diagonal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "horizontal"},  # Onda horizontal
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "random"},     # Aleatória
	{"type": "blaster_wave", "count": 3, "delay": 0.6, "pattern": "vertical"},    # Vertical
]

var current_phase: int = 0
var is_attacking: bool = false

@onready var spawner = get_parent().get_node("BlasterSpawner")

# Variável para garantir que a inicialização rode só uma vez
var foi_inicializado = false

func _ready():
	visibility_changed.connect(_on_visibility_changed)
	if visible:
		inicializar()

func _on_visibility_changed():
	if visible and not foi_inicializado:
		inicializar()

func inicializar():
	foi_inicializado = true
	execute_next_phase()

func execute_next_phase():
	if current_phase >= attack_sequence.size():
		return
	
	var phase = attack_sequence[current_phase]
	is_attacking = true
	
	match phase.type:
		"blaster_wave":
			spawn_blaster_wave(phase.count, phase.delay, phase.pattern)
	
	current_phase += 1
	await get_tree().create_timer(2.0).timeout
	execute_next_phase()

func spawn_blaster_wave(count: int, delay: float, pattern: String):
	for i in range(count):
		spawner.spawn_blaster(pattern)
		await get_tree().create_timer(delay).timeout
