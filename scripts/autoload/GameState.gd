extends Node
## Global game state: scrap currency, zone unlocks and best scores.
## Persisted to user://save.json. Also owns hub <-> zone scene travel.

signal scrap_changed(total: int)
signal best_score_changed(zone_id: String, score: int)

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1
const HUB_SCENE := "res://scenes/hub/hub.tscn"

## Every zone the hub knows about. Portals reference zones by these ids.
const ZONES := {
	"toxic_coil": {
		"name": "The Toxic Coil",
		"scene": "res://scenes/zones/toxic_coil/toxic_coil.tscn",
	},
	"derailed_metro": {
		"name": "Derailed Metro",
		"scene": "res://scenes/zones/derailed_metro/derailed_metro.tscn",
	},
}

var scrap: int = 0
var best_scores: Dictionary = {}  # zone_id -> int
var unlocked_zones: Array[String] = ["toxic_coil", "derailed_metro"]

## Zone the player last entered. The hub spawns the player in front of its portal.
## Not saved: a fresh launch starts in the middle of the hub.
var last_zone_id: String = ""


func _ready() -> void:
	load_game()


func add_scrap(amount: int) -> void:
	if amount == 0:
		return
	scrap = maxi(scrap + amount, 0)
	scrap_changed.emit(scrap)
	save_game()


func get_best_score(zone_id: String) -> int:
	return best_scores.get(zone_id, 0)


func is_zone_unlocked(zone_id: String) -> bool:
	return zone_id in unlocked_zones


func get_zone_name(zone_id: String) -> String:
	return ZONES.get(zone_id, {}).get("name", zone_id)


## Call once when a zone run ends. Records the best score, awards scrap
## (score / 10) and saves. Returns what the results screen needs.
func finish_run(zone_id: String, score: int) -> Dictionary:
	var previous_best := get_best_score(zone_id)
	var is_new_best := score > previous_best
	if is_new_best:
		best_scores[zone_id] = score
		best_score_changed.emit(zone_id, score)
	@warning_ignore("integer_division")
	var scrap_earned := score / 10
	scrap += scrap_earned
	scrap_changed.emit(scrap)
	save_game()
	return {
		"score": score,
		"best_score": get_best_score(zone_id),
		"is_new_best": is_new_best,
		"scrap_earned": scrap_earned,
	}


func enter_zone(zone_id: String) -> void:
	if not ZONES.has(zone_id):
		push_error("GameState: unknown zone '%s'" % zone_id)
		return
	if not is_zone_unlocked(zone_id):
		return
	last_zone_id = zone_id
	get_tree().change_scene_to_file(ZONES[zone_id]["scene"])


func return_to_hub() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(HUB_SCENE)


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"scrap": scrap,
		"best_scores": best_scores,
		"unlocked_zones": unlocked_zones,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameState: could not write %s (%s)" % [SAVE_PATH, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("GameState: save file is unreadable, starting fresh")
		return
	# JSON numbers come back as floats, so cast everything explicitly.
	scrap = int(data.get("scrap", 0))
	best_scores.clear()
	var saved_scores = data.get("best_scores", {})
	if typeof(saved_scores) == TYPE_DICTIONARY:
		for zone_id in saved_scores:
			best_scores[str(zone_id)] = int(saved_scores[zone_id])
	var saved_unlocks = data.get("unlocked_zones", [])
	if typeof(saved_unlocks) == TYPE_ARRAY:
		for zone_id in saved_unlocks:
			if str(zone_id) not in unlocked_zones:
				unlocked_zones.append(str(zone_id))
	scrap_changed.emit(scrap)
