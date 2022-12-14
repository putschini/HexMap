tool
extends Spatial

onready var units_node = $Units

var grid_chunk_scene := preload("res://HexGridChunk.tscn")

var cell_count_x := HexMetrics.chunk_count_x * HexMetrics.chunk_size_x
var cell_count_z := HexMetrics.chunk_count_z * HexMetrics.chunk_size_z

var chunks := Array()

var cells := Array()

var units := Array()

func add_unit(var cell: HexCell, var unit: Unit):
	cell.unit = unit
	unit.cell = cell
	unit.translation = cell.center
	units.push_back(unit)
	units_node.add_child(unit)

func move_unit(var initial: HexCell, var destination: HexCell) -> bool:
	var unit = initial.unit
	var path = find_path(initial, destination, unit.speed)
	if not path.empty():
		unit.path = path
		initial.unit = null
		destination.unit = unit
		unit.cell = destination
		return true
	return false

func _ready():
	create_chunks()
	create_cells()
	update()

func _process(_delta):
	update()

func update() -> void:
	for chunk in chunks:
		chunk.update()

func create_chunks() -> void:
	chunks.resize(HexMetrics.chunk_count_z * HexMetrics.chunk_count_x)
	var i := 0
	for z in range(0, HexMetrics.chunk_count_z):
		for x in range(0, HexMetrics.chunk_count_x):
			var new_chunk = grid_chunk_scene.instance()
			chunks[i] = new_chunk
			add_child(new_chunk)
			i += 1

func create_cells() -> void:
	cells.resize(cell_count_z * cell_count_x)
	var i := 0
	for z in range(0, cell_count_z):
		for x in range(0, cell_count_x):
			create_cell( x, z, i )
			i += 1

func create_cell(var x: int, var z: int, var i: int ) -> void:
	var position := HexMetrics.cell_center_from_offset(x, z)
	var coordinate := HexMetrics.cell_coordinate_from_offset(x, z)
	var cell = HexCell.new(coordinate, position)
	add_cell_to_chunk(x, z, cell)
	cells[i] = cell
	if x > 0:
		cell.set_neighbor(HexDirection.W, cells[i - 1])
	if z > 0:
		if z & 1 == 0:
			cell.set_neighbor(HexDirection.SE, cells[i - cell_count_x])
			if x > 0:
				cell.set_neighbor(HexDirection.SW, cells[i - cell_count_x - 1])
		else:
			cell.set_neighbor(HexDirection.SW, cells[i - cell_count_x])
			if x < cell_count_x - 1:
				cell.set_neighbor(HexDirection.SE, cells[i - cell_count_x + 1])

func add_cell_to_chunk(var x: int, var z: int, var cell: HexCell) -> void:
	var chunk_x = floor(x / HexMetrics.chunk_size_x)
	var chunk_z = floor(z / HexMetrics.chunk_size_z)
	var chunk = chunks[chunk_x + chunk_z * HexMetrics.chunk_count_x]

	var cell_local_x = x - chunk_x * HexMetrics.chunk_size_x
	var cell_local_z = z - chunk_z * HexMetrics.chunk_size_z
	chunk.add_cell(cell_local_x + cell_local_z * HexMetrics.chunk_size_x, cell)

func get_cell(var coordinate: HexCoordinate) -> HexCell:
	var z = coordinate.z
	var x = coordinate.x + z / 2
	if z < 0 || z >= cell_count_z || x < 0 || x >= cell_count_x:
		return null
	var index = x + z * cell_count_x
	return cells[index]
#	var index = coordinate.x + coordinate.z * HexMetrics.chunk_size_x * HexMetrics.chunk_count_x + coordinate.z / 2#	var chunk_x = int(coordinate.x / HexMetrics.chunk_size_x)
#	var chunk_x = int(coordinate.x / HexMetrics.chunk_size_x)
#	var chunk_z = int(coordinate.z / HexMetrics.chunk_size_z)
#	var cell_local_x = coordinate.x - chunk_x * HexMetrics.chunk_size_x
#	var cell_local_z = coordinate.z - chunk_z * HexMetrics.chunk_size_z
#	var index = cell_local_x + cell_local_z * HexMetrics.chunk_size_x + floor(coordinate.z / 2)
#	return chunks[chunk_x + chunk_z * HexMetrics.chunk_count_x].cells[index]

func clear_highlights() -> void:
	for cell in cells:
		if cell.highlight_enabled:
			cell.disable_highlight()
			cell.needs_update()

func find_path(var from: HexCell, var to: HexCell, var speed: int) -> Array:
	for cell in cells:
		cell.distance = cell.coordinate.distance_to(from.coordinate) * 5 + 1
		cell.path_from = null
		cell.to_cell = to
		cell.disable_highlight()
		cell.needs_update()

	from.enable_highlight(Color.blue)
	to.enable_highlight(Color.red)
	var frontier := Array()
	from.distance = 0
	frontier.push_back(from)
	var turn = 0
	var last_turn_distance = 0

	var result = Array()
	while(not frontier.empty()):
		var current =  frontier.pop_front()
		if current == to:
			result.push_front(to)
			current = current.path_from
			while current != null:
#				if current == from:
#					break
#				if  current == to:
#					continue
				current.enable_highlight(Color.yellow + Color(current.turn * 0.2, current.turn * 0.2, current.turn * 0.2) )
				result.push_front(current)
				current = current.path_from
			break
		for direction in HexDirection.values():
			var neighbor = current.get_neighbor(direction)
			if neighbor == null or neighbor.unit != null:
				continue
			if HexEdgeType.get_edge_type(current.elevation, neighbor.elevation) == HexEdgeType.Cliff:
				continue
			if current.walled != neighbor.walled and not current.has_road_through_edge(direction):
				continue
			var movement_cost = current.get_movement_cost(direction)
			var new_distance = current.distance + movement_cost
			if last_turn_distance + speed < new_distance:
				turn += 1
				last_turn_distance = current.distance
			if new_distance < neighbor.distance:
				neighbor.distance = new_distance
				neighbor.turn = turn
				neighbor.path_from = current
				frontier.push_back(neighbor)
		frontier.sort_custom(HexCell, "sort_distance")
	return result

