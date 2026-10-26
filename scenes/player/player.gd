extends CharacterBody3D
## Hub third-person controller: walk, sprint, jump, mouse orbit camera.
## The body never rotates; only the Body mesh turns to face movement and the
## CameraPivot yaws independently, so the camera orbit stays smooth.

@export var walk_speed := 4.5
@export var sprint_speed := 8.0
@export var jump_velocity := 5.5
@export var acceleration := 14.0
@export var air_control := 0.35
@export var turn_speed := 12.0
@export var mouse_sensitivity := 0.0025
@export_range(-89.0, 0.0) var min_pitch_deg := -65.0
@export_range(0.0, 89.0) var max_pitch_deg := 35.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var body: Node3D = $Body
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D


func _ready() -> void:
	add_to_group("player")
	spring_arm.add_excluded_object(get_rid())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotation.y -= event.relative.x * mouse_sensitivity
		spring_arm.rotation.x = clampf(
			spring_arm.rotation.x - event.relative.y * mouse_sensitivity,
			deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (camera_pivot.global_basis * Vector3(input.x, 0.0, input.y))
	direction.y = 0.0
	direction = direction.normalized() * input.length()

	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var control := 1.0 if is_on_floor() else air_control
	var target := direction * speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * control * speed * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * control * speed * delta)

	if direction.length_squared() > 0.01:
		var facing := atan2(-direction.x, -direction.z)
		body.rotation.y = lerp_angle(body.rotation.y, facing, minf(turn_speed * delta, 1.0))

	move_and_slide()


## Place the player at a spawn marker, facing and looking the way it faces.
func spawn_at(marker: Node3D) -> void:
	global_position = marker.global_position
	velocity = Vector3.ZERO
	var yaw := marker.global_rotation.y
	body.rotation.y = yaw
	camera_pivot.rotation.y = yaw
	spring_arm.rotation.x = deg_to_rad(-15.0)
