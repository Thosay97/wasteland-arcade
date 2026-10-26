extends CanvasLayer
## Hub HUD: scrap total, and a hint whenever the cursor is free (mouse look off).

@onready var scrap_label: Label = $ScrapLabel
@onready var look_hint: Label = $LookHint


func _ready() -> void:
	GameState.scrap_changed.connect(_on_scrap_changed)
	_on_scrap_changed(GameState.scrap)


func _process(_delta: float) -> void:
	look_hint.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED


func _on_scrap_changed(total: int) -> void:
	scrap_label.text = "SCRAP  %d" % total
