class_name HexCell

var center : Vector3
var coordinate : HexCoordinate

var chunk # := HexGridChunk

func needs_update() -> void:
	chunk.needs_update = true
	for neighbor in neighbors:
		if neighbor != null and neighbor.chunk != chunk:
			neighbor.chunk.needs_update = true

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
	if elevation != new_elevation:
		elevation = new_elevation
		center.y = (elevation * HexMetrics.elevation_height) + ( HexMetrics.cell_perturb_elevation_strength * Noise.sampler.get_noise_3dv(coordinate.xyz()) )
		needs_update()

func get_edge_type(var direction: int):
	return HexEdgeType.get_edge_type( elevation, neighbors[direction].elevation )

func get_cell_edge_type(var other: HexCell):
	return HexEdgeType.get_edge_type( elevation, other.elevation )

var color := Color.white

func set_color(var new_color: Color ) -> void:
	if color != new_color:
		color = new_color
		needs_update()

func _init(var coord: HexCoordinate, var center_vec: Vector3):
	center = center_vec
	coordinate = coord
	neighbors.resize( HexDirection.values().size() )
	set_elevation(0)
