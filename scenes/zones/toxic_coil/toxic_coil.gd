extends Node3D
## The Toxic Coil: grid snake in a flooded sewer chamber.
## Owns the grid, tick timer, canister, debris, scoring and the run flow.

const ZONE_ID := "toxic_coil"
const GRID_SIZE := Vector2i(20, 20)
const CELL_SIZE := 1.0
const START_CELL := Vector2i(4, 10)
const START_LENGTH := 3
const START_DIRECTION := Vector2i.RIGHT
const POINTS_PER_CANISTER := 10
const CANISTERS_PER_SPEEDUP := 5
const START_INTERVAL := 0.16
const SPEEDUP_FACTOR := 0.88
const MIN_INTERVAL := 0.06
const DEATH_DELAY := 1.0

## Fixed debris layout in grid cells. The start row is kept clear.
const DEBRIS_CELLS: Array[Vector2i] = [
	Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4),
	Vector2i(14, 3), Vector2i(14, 4),
	Vector2i(3, 15), Vector2i(4, 15),
	Vector2i(15, 14), Vector2i(15, 15), Vector2i(16, 15),
	Vector2i(10, 6), Vector2i(9, 14), Vector2i(17, 8),
]

enum State { READY, PLAYING, DEAD, RESULTS }

@export var debris_material: Material
@export var rebar_material: Material

var state := State.READY
var score := 0
var canisters_eaten := 0
var move_interval := START_INTERVAL

var _tick_time := 0.0
var _canister_cell := Vector2i.ZERO
var _debris := {}  # Vector2i -> true
var _shake := 0.0
var _camera_origin: Vector3
var _message_timer := 0.0
var _rng := RandomNumberGenerator.new()

@onready var serpent: Serpent = $Serpent
@onready var canister: Node3D = $Canister
@onready var debris_root: Node3D = $Arena/Debris
@onready var camera: Camera3D = $Camera3D
@onready var score_label: Label = $HUD/ScoreLabel
@onready var best_label: Label = $HUD/BestLabel
@onready var speed_label: Label = $HUD/SpeedLabel
@onready var message_label: Label = $HUD/Message
@onready var results: ResultsScreen = $ResultsScreen
@onready var pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_rng.randomize()
	_camera_origin = camera.position
	serpent.cell_size = CELL_SIZE
	serpent.grid_origin = cell_to_world(Vector2i.ZERO)
	_build_debris()
	results.retry_requested.connect(reset_run)
	reset_run()


func reset_run() -> void:
	state = State.READY
	score = 0
	canisters_eaten = 0
	move_interval = START_INTERVAL
	_tick_time = 0.0
	serpent.reset(START_CELL, START_LENGTH, START_DIRECTION)
	_place_canister()
	pause_menu.enabled = true
	_show_message("Arrow keys or WASD to start", 0.0)
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	var dir := _direction_from_event(event)
	if dir == Vector2i.ZERO:
		return
	match state:
		State.READY:
			if dir != -serpent.direction:
				serpent.queue_direction(dir)
				_start_run()
		State.PLAYING:
			serpent.queue_direction(dir)


func _process(delta: float) -> void:
	_animate_canister(delta)
	_update_shake(delta)
	_update_message(delta)
	if state != State.PLAYING:
		return
	_tick_time += delta
	while _tick_time >= move_interval and state == State.PLAYING:
		_tick_time -= move_interval
		_step()
	if state == State.PLAYING:
		serpent.update_visuals(clampf(_tick_time / move_interval, 0.0, 1.0))


func _start_run() -> void:
	state = State.PLAYING
	_tick_time = 0.0
	_show_message("", 0.0)


func _step() -> void:
	var next := serpent.next_head()
	var grow := next == _canister_cell
	if not _is_inside(next) or _debris.has(next) or serpent.occupies(next, grow):
		_die()
		return
	serpent.advance(next, grow)
	if grow:
		_on_canister_eaten()


func _on_canister_eaten() -> void:
	canisters_eaten += 1
	score += POINTS_PER_CANISTER
	if canisters_eaten % CANISTERS_PER_SPEEDUP == 0:
		move_interval = maxf(move_interval * SPEEDUP_FACTOR, MIN_INTERVAL)
		_show_message("SPEED UP", 1.0)
	_update_hud()
	if not _place_canister():
		_end_run("COIL COMPLETE")


func _die() -> void:
	state = State.DEAD
	serpent.update_visuals(1.0)
	serpent.set_dead()
	_shake = 0.35
	_end_run("RUN OVER")


func _end_run(title: String) -> void:
	state = State.DEAD
	pause_menu.enabled = false
	await get_tree().create_timer(DEATH_DELAY).timeout
	if not is_inside_tree():
		return
	state = State.RESULTS
	var result := GameState.finish_run(ZONE_ID, score)
	_update_hud()
	results.show_results(result, title)


## Moves the canister to a random free cell. Returns false if none is left.
func _place_canister() -> bool:
	var free: Array[Vector2i] = []
	for y in GRID_SIZE.y:
		for x in GRID_SIZE.x:
			var cell := Vector2i(x, y)
			if not _debris.has(cell) and not serpent.occupies(cell, true):
				free.append(cell)
	if free.is_empty():
		canister.visible = false
		return false
	_canister_cell = free[_rng.randi_range(0, free.size() - 1)]
	canister.position = cell_to_world(_canister_cell)
	canister.visible = true
	return true


func _build_debris() -> void:
	var chunk := BoxMesh.new()
	chunk.size = Vector3(0.85, 0.7, 0.85)
	var bar := CylinderMesh.new()
	bar.top_radius = 0.03
	bar.bottom_radius = 0.03
	bar.height = 1.0
	bar.radial_segments = 6
	for cell in DEBRIS_CELLS:
		_debris[cell] = true
		var block := MeshInstance3D.new()
		block.mesh = chunk
		block.material_override = debris_material
		block.position = cell_to_world(cell) + Vector3(0, 0.3, 0)
		block.rotation = Vector3(_rng.randf_range(-0.15, 0.15), _rng.randf_range(0, TAU), _rng.randf_range(-0.15, 0.15))
		debris_root.add_child(block)
		var rebar := MeshInstance3D.new()
		rebar.mesh = bar
		rebar.material_override = rebar_material
		rebar.position = Vector3(0.2, 0.4, 0.1)
		rebar.rotation = Vector3(0.5, 0, 0.4)
		block.add_child(rebar)


func cell_to_world(cell: Vector2i) -> Vector3:
	var origin := -Vector3(GRID_SIZE.x - 1, 0, GRID_SIZE.y - 1) * CELL_SIZE * 0.5
	return origin + Vector3(cell.x, 0, cell.y) * CELL_SIZE


func _is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_SIZE.x and cell.y < GRID_SIZE.y


func _direction_from_event(event: InputEvent) -> Vector2i:
	if event.is_echo():
		return Vector2i.ZERO
	if event.is_action_pressed("move_forward"):
		return Vector2i.UP
	if event.is_action_pressed("move_back"):
		return Vector2i.DOWN
	if event.is_action_pressed("move_left"):
		return Vector2i.LEFT
	if event.is_action_pressed("move_right"):
		return Vector2i.RIGHT
	return Vector2i.ZERO


func _animate_canister(delta: float) -> void:
	canister.rotate_y(delta * 1.5)
	canister.position.y = 0.15 + sin(Time.get_ticks_msec() * 0.004) * 0.08


func _update_shake(delta: float) -> void:
	if _shake <= 0.0:
		camera.position = _camera_origin
		return
	_shake = maxf(_shake - delta, 0.0)
	var strength := _shake * 0.6
	camera.position = _camera_origin + Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)) * strength


func _show_message(text: String, duration: float) -> void:
	message_label.text = text
	message_label.visible = text != ""
	_message_timer = duration


func _update_message(delta: float) -> void:
	if _message_timer <= 0.0:
		return
	_message_timer -= delta
	if _message_timer <= 0.0:
		message_label.visible = false


func _update_hud() -> void:
	score_label.text = "SCORE  %d" % score
	best_label.text = "BEST  %d" % GameState.get_best_score(ZONE_ID)
	@warning_ignore("integer_division")
	var level := 1 + canisters_eaten / CANISTERS_PER_SPEEDUP
	speed_label.text = "SPEED  %d" % level
