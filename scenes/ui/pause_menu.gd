class_name PauseMenu
extends CanvasLayer
## Shared zone pause menu: Esc pauses, then Resume or quit to the hub.
## Zones set `enabled` to false while their results screen is up.

var enabled := true

@onready var resume_button: Button = $Root/Panel/Margin/VBox/ResumeButton
@onready var hub_button: Button = $Root/Panel/Margin/VBox/HubButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(close)
	hub_button.pressed.connect(GameState.return_to_hub)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if visible:
		get_viewport().set_input_as_handled()
		close()
	elif enabled:
		get_viewport().set_input_as_handled()
		open()


func open() -> void:
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false
