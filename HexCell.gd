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
		update_road_on_elevation_change()
		needs_update()

func get_edge_type(var direction: int):
	return HexEdgeType.get_edge_type( elevation, neighbors[direction].elevation )

func get_cell_edge_type(var other: HexCell):
	return HexEdgeType.get_edge_type( elevation, other.elevation )

func get_elevation_difference(var direction: int) -> int:
	return int(abs( elevation - neighbors[direction].elevation ))

# Prevent uphill river flow
func update_river_on_elevation_change() -> void:
	if has_outgoing_river and elevation < neighbors[outgoing_river].elevation:
		remove_outgoing_river()
	if has_incoming_river and elevation > neighbors[incoming_river].elevation:
		remove_incoming_river()

# Prevent roads up/down hills
func update_road_on_elevation_change() -> void:
	for direction in HexDirection.values():
		if roads[direction] and get_elevation_difference(direction) > 1:
			set_road(direction, false)

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

func get_river_begin_or_end() -> int:
	return incoming_river if has_incoming_river else outgoing_river

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
#	needs_update_self_only()
	
	neighbor.remove_incoming_river()
	neighbor.has_incoming_river = true;
	neighbor.incoming_river = HexDirection.oposite(direction)
#	neighbor.needs_update_self_only()
	set_road(direction, false)

func river_bed_elevation( ) -> float:
	return (elevation + HexMetrics.river_bed_offset) * HexMetrics.elevation_height

func river_surface_elevation( ) -> float:
	return (elevation + HexMetrics.river_surface_offset) * HexMetrics.elevation_height

########################### ROAD ##############################

var roads : Array

func has_road( ) -> bool:
	for road in roads:
		if road:
			return true
	return false

func has_road_through_edge(var direction: int) -> bool:
	return roads[direction]

func set_road(var direction: int, var value: bool) -> void:
	roads[direction] = value
	needs_update_self_only()
	neighbors[direction].roads[HexDirection.oposite(direction)] = value
	neighbors[direction].needs_update_self_only()

func add_road(var direction: int) -> void:
	if not roads[direction] and not has_river_through_edge(direction) and get_elevation_difference(direction) <= 1:
		set_road(direction, true)

func remove_roads( ) -> void:
	for direction in HexDirection.values():
		if roads[direction]:
			set_road(direction, false)

########################### WALL ##############################

var walled := false

func set_walled(var new_walled: bool) -> void:
	if walled != new_walled:
		walled = new_walled
		needs_update()

var unit

var distance := 0
var turn := 0
var to_cell
var path_from

func get_movement_cost(var direction: int) -> int:
	if has_road_through_edge(direction):
		return 1
	else:
		if HexEdgeType.get_edge_type(elevation, neighbors[direction].elevation) == HexEdgeType.Flat:
			return 5
		else:
			return 10

var highlight_enabled := false
var highlight_color : Color

func enable_highlight(var color: Color) -> void:
	highlight_enabled = true
	highlight_color = color
	needs_update_self_only()

func disable_highlight( ) -> void:
	highlight_enabled = false

func _init(var coord: HexCoordinate, var center_vec: Vector3):
	center = center_vec
	coordinate = coord
	neighbors.resize( HexDirection.values().size() )
	roads.resize( HexDirection.values().size() )
	for i in HexDirection.values():
		roads[i] = false
	set_elevation(0)

static func sort_distance(var c1: HexCell, var c2: HexCell ) -> bool:
	return c1.distance + c1.coordinate.distance_to(c1.to_cell.coordinate) * 5 < c2.distance + c2.coordinate.distance_to(c2.to_cell.coordinate) * 5
