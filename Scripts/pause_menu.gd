extends Control

@onready var video_player: VideoStreamPlayer = $PauseVideo
@onready var menu_container: Control = $"."
@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var quit_button: Button = $VBoxContainer/QuitButton


func _ready() -> void:
	hide()
	video_player.finished.connect(_on_video_finished)
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

# Esta é a função que será chamada de fora para iniciar o processo de pausa.
func start_pause() -> void:
	get_tree().paused = true  # Isso aqui pode bugar a interação com o botão
	show()
	menu_container.hide()
	video_player.play()

# Chamada automaticamente quando o sinal "finished" do VideoStreamPlayer é emitido.
func _on_video_finished() -> void:
	video_player.paused = true  # Isso aqui pode bugar a interação com o botão
	menu_container.show()


# Chamada quando o botão "Continuar" é pressionado.
func _on_resume_pressed() -> void:
	get_tree().paused = false   # Isso aqui pode bugar a interação com o botão
	queue_free()


# Chamada quando o botão "Sair" é pre*ssionado.*
func _on_quit_pressed() -> void:
	get_tree().paused = false  # Isso aqui pode bugar a interação com o botão
	get_tree().quit()
