class_name HexCell

var center : Vector3
var coordinate : HexCoordinate

var chunk # := HexGridChunk

func needs_update() -> void:
	chunk.needs_update = true
	for neighbor in neighbors:
		if neighbor != null and neighbor.chunk != chunk:
			neighbor.chunk.needs_update = true

func needs_update_self_only() -> void:
	chunk.needs_update = true

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
		update_river_on_elevation_change()
		needs_update()

func get_edge_type(var direction: int):
	return HexEdgeType.get_edge_type( elevation, neighbors[direction].elevation )

func get_cell_edge_type(var other: HexCell):
	return HexEdgeType.get_edge_type( elevation, other.elevation )

# Prevent uphill river flow
func update_river_on_elevation_change() -> void:
	if has_outgoing_river and elevation < neighbors[outgoing_river].elevation:
		remove_outgoing_river()
	if has_incoming_river and elevation > neighbors[incoming_river].elevation:
		remove_incoming_river()

########################### COLOR ##############################
var color := Color.white

func set_color(var new_color: Color ) -> void:
	if color != new_color:
		color = new_color
		needs_update()

########################### RIVER ##############################
var has_incoming_river := false
var has_outgoing_river := false

var incoming_river := 0
var outgoing_river := 0

func has_river() -> bool:
	return has_incoming_river or has_outgoing_river

func has_river_begin_xor_end() -> bool:
	return has_incoming_river != has_outgoing_river

func has_river_through_edge(var direction: int) -> bool:
	return (has_incoming_river and incoming_river == direction) or (has_outgoing_river and outgoing_river == direction)

func remove_outgoing_river() -> void:
	if has_outgoing_river:
		has_outgoing_river = false
		needs_update_self_only()
		var neighbor = neighbors[outgoing_river]
		if neighbor != null and neighbor.has_incoming_river:
			neighbor.has_incoming_river = false
			neighbor.needs_update_self_only()

func remove_incoming_river() -> void:
	if has_incoming_river:
		has_incoming_river = false
		needs_update_self_only()
		var neighbor = neighbors[incoming_river]
		if neighbor != null and neighbor.has_outgoing_river:
			neighbor.has_outgoing_river = false
			neighbor.needs_update_self_only()

func remove_river() -> void:
	remove_incoming_river()
	remove_outgoing_river()

func set_outgoing_river(var direction: int) -> void:
	if has_outgoing_river and outgoing_river == direction:
		return
	var neighbor = neighbors[direction]
	if neighbor == null or elevation < neighbor.elevation:
		return
	
	remove_outgoing_river()
	if has_incoming_river and incoming_river == direction:
		remove_incoming_river()
	
	has_outgoing_river = true
	outgoing_river = direction
	needs_update_self_only()
	
	neighbor.remove_incoming_river()
	neighbor.has_incoming_river = true;
	neighbor.incoming_river = HexDirection.oposite(direction)
	neighbor.needs_update_self_only()

func river_bed_elevation( ) -> float:
	return (elevation + HexMetrics.river_bed_offset) * HexMetrics.elevation_height

func river_surface_elevation( ) -> float:
	return (elevation + HexMetrics.river_surface_offset) * HexMetrics.elevation_height

func _init(var coord: HexCoordinate, var center_vec: Vector3):
	center = center_vec
	coordinate = coord
	neighbors.resize( HexDirection.values().size() )
	set_elevation(0)
