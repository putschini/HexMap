class_name HexCell

var center : Vector3
var coordinate : HexCoordinate
var color := Color.white

########################## NEIGHBOR ############################
var neighbors : Array

func get_neighbor(var direction : int ) -> HexCell:
	return neighbors[direction]

func set_neighbor(var direction: int, var cell: HexCell) -> void:
	neighbors[direction] = cell
	cell.neighbors[HexDirection.oposite(direction)] = self

######################### ELEVATION ############################
var elevation : int

func get_edge_type(var direction: int):
	return HexEdgeType.get_edge_type( elevation, neighbors[direction].elevation )

func get_cell_edge_type(var other: HexCell):
	return HexEdgeType.get_edge_type( elevation, other.elevation )

func _init(var coord: HexCoordinate, var center_vec: Vector3):
	center = center_vec
	coordinate = coord
	neighbors.resize( HexDirection.values().size() )
