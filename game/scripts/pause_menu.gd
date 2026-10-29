extends Control

@onready var resume_button: Button = $MenuContainer/ResumeButton
@onready var controls_button: Button = $MenuContainer/ControlsButton
@onready var main_menu_button: Button = $MenuContainer/MainMenuButton
@onready var controls: Label = $MenuContainer/ControlsButton/ControlsInfo

func _ready() -> void:
	visible = false
	controls.visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	controls_button.pressed.connect(_on_controls_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if get_tree().paused:
			unpause_game()
		else:
			pause_game()

func pause_game() -> void:
	visible = true
	get_tree().paused = true 

func unpause_game() -> void:
	visible = false
	get_tree().paused = false 

func _on_resume_pressed() -> void:
	unpause_game()

func _on_controls_pressed() -> void:
	controls.visible = not controls.visible

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
