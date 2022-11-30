tool
extends Spatial

var width = 6
var height = 6

onready var hex_mesh := $HexMesh

var cells := Array()

func _ready():
	cells.resize(width * height)
	var i := 0
	for z in range(0, height):
		for x in range(0, width):
			create_cell( x, z, i )
			i += 1
	hex_mesh.triangulate(cells)

func create_cell(var x: int, var z: int, var i: int ) -> void:
	var position := HexMetrics.cell_center_from_offset(x, z)
	var coordinate := HexMetrics.cell_coordinate_from_offset(x, z)
	var cell = HexCell.new(coordinate, position)
	cells[i] = cell

	if x > 0:
		cell.set_neighbor(HexDirection.W, cells[i - 1])
	if z > 0:
		if z & 1 == 0:
			cell.set_neighbor(HexDirection.SE, cells[i - width])
			if x > 0:
				cell.set_neighbor(HexDirection.SW, cells[i - width - 1])
		else:
			cell.set_neighbor(HexDirection.SW, cells[i - width])
			if x < width - 1:
				cell.set_neighbor(HexDirection.SE, cells[i - width + 1])
				
	#TODO: MOVE TO APROPRIATE PLAACE
	var label := Label3D.new()
	label.translation = cell.center + Vector3(0, 2, 0)
	label.text = cell.coordinate.to_string()
	label.scale = Vector3(8,8,8)
	label.modulate = Color.black
	label.billboard = true
	$Labels.add_child(label)

func update() -> void:
	hex_mesh.triangulate(cells)
	for labels in $Labels.get_children():
		labels.free()
	for cell in cells:
		var label := Label3D.new()
		label.translation = cell.center + Vector3(0, 2, 0)
		label.text = cell.coordinate.to_string()
		label.scale = Vector3(8,8,8)
		label.modulate = Color.black
		label.billboard = true
		$Labels.add_child(label)
