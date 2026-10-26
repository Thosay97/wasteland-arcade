class_name ResultsScreen
extends CanvasLayer
## Shared end-of-run screen for every zone: score, best score, scrap earned,
## Retry and Return to Hub. Pass it the Dictionary from GameState.finish_run().

signal retry_requested

@onready var title_label: Label = $Root/Panel/Margin/VBox/Title
@onready var score_label: Label = $Root/Panel/Margin/VBox/Score
@onready var best_label: Label = $Root/Panel/Margin/VBox/Best
@onready var scrap_label: Label = $Root/Panel/Margin/VBox/Scrap
@onready var retry_button: Button = $Root/Panel/Margin/VBox/Buttons/RetryButton
@onready var hub_button: Button = $Root/Panel/Margin/VBox/Buttons/HubButton


func _ready() -> void:
	visible = false
	retry_button.pressed.connect(_on_retry_pressed)
	hub_button.pressed.connect(GameState.return_to_hub)


func show_results(result: Dictionary, title := "RUN OVER") -> void:
	title_label.text = title
	score_label.text = "SCORE  %d" % result.score
	if result.is_new_best:
		best_label.text = "NEW BEST!  %d" % result.best_score
	else:
		best_label.text = "BEST  %d" % result.best_score
	scrap_label.text = "+%d SCRAP" % result.scrap_earned
	visible = true
	retry_button.grab_focus()


func _on_retry_pressed() -> void:
	visible = false
	retry_requested.emit()
