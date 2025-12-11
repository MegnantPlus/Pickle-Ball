extends Control

@onready var main_container = $MainContainer # Nhớ chỉnh đường dẫn đúng node của bạn
@onready var platform_select = $PlatformSelect

func _ready():
	# Ẩn bảng chọn hệ máy lúc đầu
	platform_select.visible = false
	main_container.visible = true

func _on_play_button_pressed():
	# Chuyển sang màn hình chọn hệ máy
	main_container.visible = false
	platform_select.visible = true

func _on_pc_button_pressed():
	Global.is_mobile = false
	start_tutorial()

func _on_mobile_button_pressed():
	Global.is_mobile = true
	start_tutorial()

func start_tutorial():
	# Chuyển sang scene Tutorial 
	get_tree().change_scene_to_file("res://Map/Tutorial/tutorial_level.tscn")
