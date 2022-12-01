tool
extends Spatial

var grid_chunk_scene := preload("res://HexGridChunk.tscn")

var cell_count_x := HexMetrics.chunk_count_x * HexMetrics.chunk_size_x
var cell_count_z := HexMetrics.chunk_count_z * HexMetrics.chunk_size_z

var chunks := Array()

var cells := Array()

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

