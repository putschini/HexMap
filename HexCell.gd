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

func set_elevation(var new_elevation: int) -> void:
	elevation = new_elevation
	center.y = (elevation * HexMetrics.elevation_height) + ( HexMetrics.cell_perturb_elevation_strength * Noise.sampler.get_noise_3dv(coordinate.xyz()) )

func get_edge_type(var direction: int):
	return HexEdgeType.get_edge_type( elevation, neighbors[direction].elevation )

func get_cell_edge_type(var other: HexCell):
	return HexEdgeType.get_edge_type( elevation, other.elevation )

func _init(var coord: HexCoordinate, var center_vec: Vector3):
	center = center_vec
	coordinate = coord
	neighbors.resize( HexDirection.values().size() )
	set_elevation(0)
