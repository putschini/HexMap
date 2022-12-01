tool
extends Spatial

class_name HexGridChunk

var hex_mesh

var cells := Array()

var needs_update := true

func _init():
	cells.resize(HexMetrics.chunk_size_z * HexMetrics.chunk_size_x)
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
#	print("CHUNK READY")
	hex_mesh = $HexMesh
	pass # Replace with function body.

func add_cell(var index: int, var cell: HexCell) -> void:
#	print(index)
	cell.chunk = self
	cells[index] = cell

func update() -> void:
	if needs_update:
		needs_update = false
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
