extends CanvasLayer

enum TutorialState {
	MOVE,
	DASH,
	ATTACK,
	ATTACK2,
	TALK,
	FINISHED
}

var current_state = TutorialState.MOVE
var can_proceed = true # Para evitar inputs durante o delay

# Referências aos nós (ajuste os caminhos conforme sua cena)
@onready var label: Label = $Label
@onready var tilemap: TileMapLayer = $"../NavigationRegion2D/TileMapLayer2"

func _ready():
	update_ui()

func _process(delta):
	if not can_proceed:
		return
		
	match current_state:
		TutorialState.MOVE:
			# Verifica se o jogador apertou algum botão de movimento
			if Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("move_left"):
				complete_step(TutorialState.DASH)
		TutorialState.DASH:
			if Input.is_action_just_pressed("dash"):
				complete_step(TutorialState.ATTACK)
		TutorialState.ATTACK:
			if Input.is_action_just_pressed("atacar"):
				complete_step(TutorialState.ATTACK2)
		TutorialState.ATTACK2:
			if Input.is_action_just_pressed("atacar"):
				complete_step(TutorialState.TALK)
		TutorialState.TALK:
			if Input.is_action_just_pressed("interagir"):
				complete_step(TutorialState.FINISHED)

# Função para atualizar o texto na tela
func update_ui():
	
	match current_state:
		TutorialState.MOVE:
			label.text = "Pressione WASD para se mover!"
		TutorialState.DASH:
			label.text = "Pressione SHIFT para usar o dash!"
		TutorialState.ATTACK:
			label.text = "Pressione BOTÃO ESQUERDO DO MOUSE para atacar!"
		TutorialState.ATTACK2:
			label.text = "Segure BOTÃO ESQUERDO DO MOUSE para um ataque carregado!"
			await get_tree().create_timer(1.5).timeout
		TutorialState.TALK:
			tilemap.queue_free()
			label.text = "Pressione E para conversar e ESPAÇO para mudar o diálogo!"
		TutorialState.FINISHED:
			await get_tree().create_timer(2.0).timeout
			queue_free()

# Função que lida com a transição e o delay
func complete_step(next_state):
	can_proceed = false
	await get_tree().create_timer(1.5).timeout
	current_state = next_state
	can_proceed = true
	update_ui()
