extends CanvasLayer
## Hub HUD: scrap total.

@onready var scrap_label: Label = $ScrapLabel


func _ready() -> void:
	GameState.scrap_changed.connect(_on_scrap_changed)
	_on_scrap_changed(GameState.scrap)


func _on_scrap_changed(total: int) -> void:
	scrap_label.text = "SCRAP  %d" % total
