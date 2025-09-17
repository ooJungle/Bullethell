extends Control

@onready var video_player: VideoStreamPlayer = $CanvasLayer/PauseVideo
@onready var menu_container: CanvasLayer = $CanvasLayer
@onready var resume_button: Button = $CanvasLayer/VBoxContainer/ResumeButton
@onready var quit_button: Button = $CanvasLayer/VBoxContainer/QuitButton


func _ready() -> void:
	menu_container.hide()
 	
func start_pause() -> void:
	menu_container.show()
	video_player.play()
	video_player.paused = false

func _on_resume_button_pressed() -> void:
	menu_container.hide()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_pause_video_finished() -> void:
	video_player.paused = true
