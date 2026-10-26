extends Node3D
## The Junction: spawns the player in front of the portal they last used.

@onready var player: CharacterBody3D = $Player
@onready var default_spawn: Marker3D = $DefaultSpawn


func _ready() -> void:
	player.spawn_at(_find_spawn())


func _find_spawn() -> Marker3D:
	for portal in get_tree().get_nodes_in_group("portals"):
		if portal.zone_id == GameState.last_zone_id:
			return portal.spawn_point
	return default_spawn
