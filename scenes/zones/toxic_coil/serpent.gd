class_name Serpent
extends Node3D
## The mutant sludge serpent: its body on the grid plus pooled segment visuals.
## Cells are stored head first. Each tick the visuals slide from the previous
## cells to the current ones, so movement looks smooth while logic stays on the grid.

const MAX_QUEUED_TURNS := 2
const SEGMENT_HEIGHT := 0.4

@export var cell_size := 1.0
## Local position of the centre of cell (0, 0).
@export var grid_origin := Vector3.ZERO
@export var body_material_a: Material
@export var body_material_b: Material
@export var head_material: Material
@export var dead_material: Material

var cells: Array[Vector2i] = []
var direction := Vector2i.RIGHT

var _prev_cells: Array[Vector2i] = []
var _turn_queue: Array[Vector2i] = []
var _segment_pool: Array[MeshInstance3D] = []
var _segment_mesh: SphereMesh
var _time := 0.0

@onready var head: Node3D = $Head
@onready var head_mesh: MeshInstance3D = $Head/HeadMesh
@onready var segments_root: Node3D = $Segments


func _ready() -> void:
	_segment_mesh = SphereMesh.new()
	_segment_mesh.radius = 0.4
	_segment_mesh.height = 0.75
	_segment_mesh.radial_segments = 16
	_segment_mesh.rings = 8


func _process(delta: float) -> void:
	_time += delta


func reset(start: Vector2i, length: int, start_direction: Vector2i) -> void:
	direction = start_direction
	_turn_queue.clear()
	cells.clear()
	for i in length:
		cells.append(start - start_direction * i)
	_prev_cells = cells.duplicate()
	head_mesh.material_override = head_material
	_sync_pool()
	update_visuals(1.0)


## Buffer a turn for a later tick. Ignores repeats and 180-degree reversals.
func queue_direction(new_direction: Vector2i) -> bool:
	if _turn_queue.size() >= MAX_QUEUED_TURNS:
		return false
	var last: Vector2i = direction if _turn_queue.is_empty() else _turn_queue.back()
	if new_direction == last or new_direction == -last:
		return false
	_turn_queue.append(new_direction)
	return true


## Applies the next buffered turn and returns the cell the head moves into.
func next_head() -> Vector2i:
	if not _turn_queue.is_empty():
		direction = _turn_queue.pop_front()
	return cells[0] + direction


## True if the body would block `cell` this tick. The tail cell is free
## unless the serpent is growing, because the tail moves out of it.
func occupies(cell: Vector2i, growing: bool) -> bool:
	var count := cells.size() if growing else cells.size() - 1
	for i in count:
		if cells[i] == cell:
			return true
	return false


func advance(new_head: Vector2i, grow: bool) -> void:
	_prev_cells = cells.duplicate()
	cells.push_front(new_head)
	if grow:
		# The new tail segment starts where the old tail already is.
		_prev_cells.append(_prev_cells.back())
	else:
		cells.pop_back()
	_sync_pool()


func set_dead() -> void:
	head_mesh.material_override = dead_material


## t is how far through the current tick we are, 0..1.
func update_visuals(t: float) -> void:
	var count := cells.size()
	for i in count:
		var from := cell_to_local(_prev_cells[i])
		var to := cell_to_local(cells[i])
		var pos := from.lerp(to, t)
		if i == 0:
			head.position = pos
			var yaw := atan2(-float(direction.x), -float(direction.y))
			head.rotation.y = lerp_angle(head.rotation.y, yaw, 0.5)
			continue
		pos.y += sin(_time * 6.0 - i * 0.7) * 0.04
		var segment := _segment_pool[i - 1]
		segment.position = pos
		var from_tail := count - 1 - i
		segment.scale = Vector3.ONE * (0.7 + 0.1 * from_tail if from_tail < 3 else 1.0)


func cell_to_local(cell: Vector2i) -> Vector3:
	return grid_origin + Vector3(cell.x * cell_size, SEGMENT_HEIGHT, cell.y * cell_size)


# Grow the pool on demand and hide segments beyond the current length.
func _sync_pool() -> void:
	var needed := cells.size() - 1
	while _segment_pool.size() < needed:
		var segment := MeshInstance3D.new()
		segment.mesh = _segment_mesh
		segment.material_override = body_material_a if _segment_pool.size() % 2 == 0 else body_material_b
		segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		segments_root.add_child(segment)
		_segment_pool.append(segment)
	for i in _segment_pool.size():
		_segment_pool[i].visible = i < needed
