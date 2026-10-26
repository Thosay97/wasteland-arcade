extends Node3D
## Zone portal: a rusted doorway with a glowing sign. Shows "Press E to enter"
## while the player stands in the trigger, then asks GameState to load the zone.

@export var zone_id: String = "toxic_coil"

@onready var sign_label: Label3D = $Sign/SignLabel
@onready var prompt: Label3D = $Prompt
@onready var trigger: Area3D = $Trigger
@onready var spawn_point: Marker3D = $SpawnPoint

var _player_inside := false


func _ready() -> void:
	add_to_group("portals")
	sign_label.text = GameState.get_zone_name(zone_id).to_upper()
	prompt.visible = false
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		GameState.enter_zone(zone_id)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		prompt.visible = true


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		prompt.visible = false
