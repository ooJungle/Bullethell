extends Control

@onready var video_player: VideoStreamPlayer = $CanvasLayer/PauseVideo
@onready var despause_video_player: VideoStreamPlayer = $CanvasLayer/DespauseVideo
@onready var menu_container: CanvasLayer = $CanvasLayer
@onready var resume_button: Button = $CanvasLayer/VBoxContainer/ResumeButton
@onready var quit_button: Button = $CanvasLayer/VBoxContainer/QuitButton

func start_pause() -> void:
	Global.menu = 1
	Global.set_in_menu_state(true)
	menu_container.show()
	Global.paused = true
	video_player.play()
	video_player.paused = false

func _on_resume_button_pressed() -> void:
	despause_video_player.play()
	despause_video_player.paused = false

func _on_quit_button_pressed() -> void:
	Global.set_in_menu_state(true)
	Global.paused = false
	get_tree().change_scene_to_file("res://Cenas/Menus/menu_inicial.tscn")

func _on_pause_video_finished() -> void:
	video_player.paused = true

func _on_pause_video_2_finished() -> void:
	Global.set_in_menu_state(false)
	despause_video_player.paused = true
	menu_container.hide()
	Global.paused = false


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Cenas/Menu/SettingsMenu.tscn")
