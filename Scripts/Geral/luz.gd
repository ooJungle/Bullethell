extends PointLight2D

@export var energia_base: float = 1.0
@export var variacao_energia: float = 0.2
@export var velocidade_pisque: float = 5.0

@export var escala_base: float = 1.0
@export var variacao_escala: float = 0.05 

var noise = FastNoiseLite.new()
var time_passed = 0.0

func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 0.5 

func _process(delta: float) -> void:
	time_passed += delta * velocidade_pisque
	var noise_value = noise.get_noise_1d(time_passed)
	energy = energia_base + (noise_value * variacao_energia)
	var noise_scale = noise.get_noise_1d(time_passed + 100.0)
	texture_scale = escala_base + (noise_scale * variacao_escala)
