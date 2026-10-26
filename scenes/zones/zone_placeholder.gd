extends Node3D
## Temporary stand-in for a zone until its gameplay is built.
## Enter fakes a finished run so saving and the hub return can be tested.

const TEST_SCORE := 100

@export var zone_id: String = "toxic_coil"

@onready var info: Label = $UI/Info


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var result := GameState.finish_run(zone_id, TEST_SCORE)
		print("Test run in %s: %s" % [zone_id, result])
		GameState.return_to_hub()
	elif event.is_action_pressed("ui_cancel"):
		GameState.return_to_hub()


func _refresh() -> void:
	info.text = "%s\n(placeholder zone)\n\nBest score: %d   Scrap: %d\n\n[Enter] fake a run (score %d)\n[Esc] return to hub" % [
		GameState.get_zone_name(zone_id).to_upper(),
		GameState.get_best_score(zone_id),
		GameState.scrap,
		TEST_SCORE,
	]
