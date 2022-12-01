tool
extends Spatial

class_name HexGridChunk

#TODO: if material is exported from HexMesh this wount be needed
onready var test_material: ShaderMaterial = preload("res://test_shader.material")
onready var river_material: ShaderMaterial = preload("res://River.material")
#var hex_mesh
onready var terrain: HexMesh = $TerrainMesh
onready var river: HexMesh = $RiverMesh

var cells := Array()

var needs_update := true

func _init():
	cells.resize(HexMetrics.chunk_size_z * HexMetrics.chunk_size_x)
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	terrain.setup(true, true, false, true)
	river.setup(false, false, true, false)
	river.set_material(river_material)

func add_cell(var index: int, var cell: HexCell) -> void:
	cell.chunk = self
	cells[index] = cell

func update() -> void:
	if needs_update:
		needs_update = false
		triangulate()
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

func commit_mesh() -> void:
	terrain.commit_mesh()
	river.commit_mesh()

func triangulate( ) -> void:
	for cell in cells:
		triangulate_cell(cell)
	commit_mesh()
	pass

func triangulate_cell( var cell : HexCell ) -> void:
	for i in HexDirection.values():
		triangulate_direction( cell, i )
	pass

func triangulate_direction( var cell : HexCell, var direction : int ) -> void:
	var center = cell.center
	var edge = EdgeVertices.new(center + HexMetrics.get_first_solid_corner(direction), center + HexMetrics.get_second_solid_corner(direction) )

	if cell.has_river():
		if cell.has_river_through_edge(direction):
			edge.v3.y = cell.river_bed_elevation()
			if cell.has_river_begin_xor_end():
				triangulate_with_river_begin_or_end(cell, direction, edge)
			else:
				triangulate_with_river(cell, direction, edge)
		else:
			triangulate_adjacent_to_river(cell, direction, edge)
	else:
		terrain.add_edge_fan(center, edge, cell.color)

	# Only triangulate half the connection because connection go from cell solid corner to neighbor solid corner
	if direction <= HexDirection.SE:
		triangulate_connection( cell, direction, edge )

func triangulate_connection( var cell : HexCell, var direction : int, var edge : EdgeVertices) -> void:
	var neighbor = cell.neighbors[direction]
	if neighbor == null:
		return

	var blend_bridge_offset = HexMetrics.get_blend_bridge(direction)
	blend_bridge_offset.y = neighbor.center.y - cell.center.y
	var neighbor_edge = EdgeVertices.new(edge.v1 + blend_bridge_offset, edge.v5 + blend_bridge_offset)

	if cell.has_river_through_edge(direction):
		neighbor_edge.v3.y = neighbor.river_bed_elevation()
		var reversed = cell.has_incoming_river and cell.incoming_river == direction
		triangulate_river_quad2(edge.v1, edge.v4, cell.river_surface_elevation(), neighbor_edge.v1, neighbor_edge.v4, neighbor.river_surface_elevation(), 0.8, reversed)

	# Rectangle blending region between hexagons
	if cell.get_edge_type(direction) == HexEdgeType.Slop:
		triangulate_slop_edge(edge, cell, neighbor_edge, neighbor)
	else:
		terrain.add_edge_strip(edge, cell.color, neighbor_edge, neighbor.color)

	var next_neighbor = cell.neighbors[HexDirection.next(direction)]
	# Only add the triangle connection in two direction, to not produce overlaping triangles
	if direction <= HexDirection.E and next_neighbor != null:
		var next_neighbor_bridge_corner = edge.v5 + HexMetrics.get_blend_bridge( HexDirection.next(direction) ) # + HexMetrics.get_elevation_offset(next_neighbor.elevation - cell.elevation)
		next_neighbor_bridge_corner.y = next_neighbor.center.y
		#Ajust cells so the triangulation becomes easier, always triangulate from the bottom to the left and right
		if cell.elevation <= neighbor.elevation:
			if cell.elevation <= next_neighbor.elevation:
				triangulate_corner(edge.v5, cell, neighbor_edge.v5, neighbor, next_neighbor_bridge_corner, next_neighbor)
			else:
				triangulate_corner(next_neighbor_bridge_corner, next_neighbor, edge.v5, cell, neighbor_edge.v5, neighbor)
		elif neighbor.elevation <= next_neighbor.elevation:
			triangulate_corner(neighbor_edge.v5, neighbor, next_neighbor_bridge_corner, next_neighbor, edge.v5, cell)
		else:
			triangulate_corner(next_neighbor_bridge_corner, next_neighbor, edge.v5, cell, neighbor_edge.v5, neighbor)

func triangulate_slop_edge( var begin_edge: EdgeVertices, var begin_cell: HexCell, var end_edge: EdgeVertices, var end_cell: HexCell ) -> void:
	var next_edge = HexMetrics.terrace_lerp_edge_interpolation(begin_edge, end_edge, 1)
	var next_color = HexMetrics.tearrace_lerp_color_interpolation(begin_cell.color, end_cell.color, 1)
	terrain.add_edge_strip( begin_edge, begin_cell.color, next_edge, next_color )
	for i in range(2, HexMetrics.terrace_steps):
		var aux_edge = next_edge
		var aux_color = next_color
		next_edge = HexMetrics.terrace_lerp_edge_interpolation(begin_edge, end_edge, i)
		next_color = HexMetrics.tearrace_lerp_color_interpolation(begin_cell.color, end_cell.color, i)
		terrain.add_edge_strip(aux_edge, aux_color, next_edge, next_color)
	terrain.add_edge_strip(next_edge, next_color, end_edge, end_cell.color)

# Triangle blending region between hexagons
# Triangulates from the bottom to the left and right
func triangulate_corner(var bottom_edge: Vector3, var bottom_cell: HexCell, var left_edge: Vector3, var left_cell: HexCell, var right_edge: Vector3, var right_cell: HexCell) -> void:
	var left_edge_type = bottom_cell.get_cell_edge_type(left_cell)
	var right_edge_type = bottom_cell.get_cell_edge_type(right_cell)
	
	if left_edge_type == HexEdgeType.Slop:
		if right_edge_type == HexEdgeType.Slop:
			#Bottom edge between 2 slops 
			triangulate_slop_corner(bottom_edge, bottom_cell, left_edge, left_cell, right_edge, right_cell)
		elif right_edge_type == HexEdgeType.Flat:
			#Left edge is the top corner between two flat cells
			triangulate_slop_corner(left_edge, left_cell, right_edge, right_cell, bottom_edge, bottom_cell)
		else:
			triangulate_slop_cliff_corner(bottom_edge, bottom_cell, left_edge, left_cell, right_edge, right_cell)
	elif left_edge_type == HexEdgeType.Flat:
		if right_edge_type == HexEdgeType.Slop:
			#Right edge is the top corner between two flat cells
			triangulate_slop_corner(right_edge, right_cell, bottom_edge, bottom_cell, left_edge, left_cell)
		#Flat-Flat, Flat-Cliff are only one triangle
		else:
			terrain.add_triangle( bottom_edge, left_edge, right_edge )
			terrain.add_triangle_color( bottom_cell.color, left_cell.color, right_cell.color )
	else: #Left Cliff
		if right_edge_type == HexEdgeType.Slop:
			triangulate_cliff_slop_corner(bottom_edge, bottom_cell, left_edge, left_cell, right_edge, right_cell)
		if right_edge_type == HexEdgeType.Cliff:
			#Use the same method as slop-cliff but rotate the edges
			if left_cell.get_cell_edge_type(right_cell) == HexEdgeType.Slop:
				if left_cell.elevation < right_cell.elevation:
					triangulate_cliff_slop_corner(right_edge, right_cell, bottom_edge, bottom_cell, left_edge, left_cell)
				else:
					triangulate_slop_cliff_corner(left_edge, left_cell, right_edge, right_cell, bottom_edge, bottom_cell)
			#Flat, Cliff are only one triangle
			else:
				terrain.add_triangle( bottom_edge, left_edge, right_edge )
				terrain.add_triangle_color( bottom_cell.color, left_cell.color, right_cell.color )
		#Cliff-Flat is only one triangle
		else:
			terrain.add_triangle( bottom_edge, left_edge, right_edge )
			terrain.add_triangle_color( bottom_cell.color, left_cell.color, right_cell.color )

#Triangulate corner between cells with 1 elevation difference
#Starts from the triangule in the top/bottom corner
func triangulate_slop_corner(var begin_edge: Vector3, var begin_cell: HexCell, var left_edge: Vector3, var left_cell: HexCell, var right_edge: Vector3, var right_cell: HexCell) -> void:
	var left_next_edge = HexMetrics.terrace_lerp_interpolation(begin_edge, left_edge, 1)
	var right_next_edge = HexMetrics.terrace_lerp_interpolation(begin_edge, right_edge, 1)
	var left_next_color = HexMetrics.tearrace_lerp_color_interpolation(begin_cell.color, left_cell.color, 1)
	var right_next_color = HexMetrics.tearrace_lerp_color_interpolation(begin_cell.color, right_cell.color, 1)
	terrain.add_triangle(begin_edge, left_next_edge, right_next_edge)
	terrain.add_triangle_color(begin_cell.color, left_next_color, right_next_color)
	for i in range(2, HexMetrics.terrace_steps):
		var left_aux_edge = left_next_edge
		var right_aux_edge = right_next_edge
		var left_aux_color = left_next_color
		var right_aux_color = right_next_color
		left_next_edge = HexMetrics.terrace_lerp_interpolation(begin_edge, left_edge, i)
		right_next_edge = HexMetrics.terrace_lerp_interpolation(begin_edge, right_edge, i)
		left_next_color = HexMetrics.tearrace_lerp_color_interpolation(begin_cell.color, left_cell.color, i)
		right_next_color = HexMetrics.tearrace_lerp_color_interpolation(begin_cell.color, right_cell.color, i)
		terrain.add_quad(left_aux_edge, right_aux_edge, left_next_edge, right_next_edge)
		terrain.add_quad_color(left_aux_color, right_aux_color, left_next_color, right_next_color)
	terrain.add_quad(left_next_edge, right_next_edge, left_edge, right_edge)
	terrain.add_quad_color(left_next_color, right_next_color, left_cell.color, right_cell.color)

#Triangulate corner between a slop and a cliff
#Create a boundary line because diffence between slop and cliff triangulations
func triangulate_slop_cliff_corner(var begin_edge: Vector3, var begin_cell: HexCell, var left_edge: Vector3, var left_cell: HexCell, var right_edge: Vector3, var right_cell: HexCell) -> void:
	var boundary_ratio = abs(1.0 / (right_cell.elevation - begin_cell.elevation))
	var boundary_edge = HexMetrics.perturb(begin_edge).linear_interpolate(HexMetrics.perturb(right_edge), boundary_ratio)
	var boundary_color = begin_cell.color.linear_interpolate(right_cell.color, boundary_ratio)
	#Left slop corner
	triangulate_slop_boundary_corner( begin_edge, begin_cell, left_edge, left_cell, boundary_edge, boundary_color )
	#The opposite edge can be a slop or a cliff
	if left_cell.get_cell_edge_type(right_cell) == HexEdgeType.Slop:
		triangulate_slop_boundary_corner(left_edge, left_cell, right_edge, right_cell, boundary_edge, boundary_color)
	else:
		terrain.add_triangle_unperturbed(HexMetrics.perturb(left_edge), HexMetrics.perturb(right_edge), boundary_edge)
		terrain.add_triangle_color(left_cell.color, right_cell.color, boundary_color)

#Triangulate corner between a cliff and a slop
#Create a boundary line because diffence between slop and cliff triangulations
func triangulate_cliff_slop_corner(var begin_edge: Vector3, var begin_cell: HexCell, var left_edge: Vector3, var left_cell: HexCell, var right_edge: Vector3, var right_cell: HexCell) -> void:
	var boundary_ratio = abs(1.0 / (left_cell.elevation - begin_cell.elevation))
	var boundary_edge = HexMetrics.perturb(begin_edge).linear_interpolate(HexMetrics.perturb(left_edge), boundary_ratio)
	var boundary_color = begin_cell.color.linear_interpolate(left_cell.color, boundary_ratio)
	#Right slop corner
	triangulate_slop_boundary_corner(right_edge, right_cell, begin_edge, begin_cell, boundary_edge, boundary_color )
	#The opposite edge can be a slop or a cliff
	if left_cell.get_cell_edge_type(right_cell) == HexEdgeType.Slop:
		triangulate_slop_boundary_corner(left_edge, left_cell, right_edge, right_cell, boundary_edge, boundary_color)
	else:
#		add_triangle(left_edge, right_edge, boundary_edge)
		terrain.add_triangle_unperturbed(HexMetrics.perturb(left_edge), HexMetrics.perturb(right_edge), boundary_edge)
		terrain.add_triangle_color(left_cell.color, right_cell.color, boundary_color)

#Triangulate slop corner to boundary edge
func triangulate_slop_boundary_corner(var begin_edge: Vector3, var begin_cell: HexCell, var left_edge: Vector3, var left_cell: HexCell, var boundary_edge: Vector3, var boundary_color: Color) -> void:
	var left_next_edge = HexMetrics.perturb(HexMetrics.terrace_lerp_interpolation(begin_edge, left_edge, 1))
	var left_next_color = HexMetrics.tearrace_lerp_color_interpolation(begin_cell.color, left_cell.color, 1)
	terrain.add_triangle_unperturbed(HexMetrics.perturb(begin_edge), left_next_edge, boundary_edge )
	terrain.add_triangle_color(begin_cell.color, left_next_color, boundary_color)
	for i in range(2, HexMetrics.terrace_steps):
		var left_aux_edge = left_next_edge
		var left_aux_color = left_next_color
		left_next_edge = HexMetrics.perturb(HexMetrics.terrace_lerp_interpolation(begin_edge, left_edge, i))
		left_next_color = HexMetrics.tearrace_lerp_color_interpolation(begin_cell.color, left_cell.color, i)
		terrain.add_triangle_unperturbed(left_aux_edge, left_next_edge, boundary_edge)
		terrain.add_triangle_color(left_aux_color, left_next_color, boundary_color)
	terrain.add_triangle_unperturbed(left_next_edge, HexMetrics.perturb(left_edge), boundary_edge)
	terrain.add_triangle_color(left_next_color, left_cell.color, boundary_color)


func triangulate_with_river(var cell: HexCell, var direction: int, var edge: EdgeVertices) -> void:
	var center = cell.center
	#Change center vertice to a line to ajust for the river
	var center_left: Vector3
	var center_right: Vector3
	if cell.has_river_through_edge(HexDirection.oposite(direction)):
		center_left = center + HexMetrics.get_first_solid_corner(HexDirection.previous(direction)) * 0.25
		center_right = center + HexMetrics.get_second_solid_corner(HexDirection.next(direction)) * 0.25
	elif cell.has_river_through_edge(HexDirection.next(direction)):
		center_left = center
		center_right = center.linear_interpolate(edge.v5, 2.0/3.0)
	elif cell.has_river_through_edge(HexDirection.previous(direction)):
		center_left = center.linear_interpolate(edge.v1, 2.0/3.0)
		center_right = center
	elif cell.has_river_through_edge(HexDirection.next2(direction)):
		center_left = center
		center_right = center + HexMetrics.get_solid_middle_corner(HexDirection.next(direction)) * (0.5 * HexMetrics.inner_to_outer)
	else:
		center_left = center + HexMetrics.get_solid_middle_corner(HexDirection.previous(direction)) * (0.5 * HexMetrics.inner_to_outer)
		center_right = center
	center = center_left.linear_interpolate(center_right, 0.5)
	var middle_edge = EdgeVertices.new(center_left.linear_interpolate(edge.v1, 0.5), center_right.linear_interpolate(edge.v5, 0.5), 1.0/6.0)
	center.y = edge.v3.y
	middle_edge.v3.y = edge.v3.y
	var reversed = cell.incoming_river == direction
	triangulate_river_quad(center_left, center_right, middle_edge.v1, middle_edge.v5, cell.river_surface_elevation(), 0.4, reversed)
	triangulate_river_quad(middle_edge.v1, middle_edge.v5, edge.v1, edge.v5, cell.river_surface_elevation(), 0.6, reversed)

	terrain.add_edge_strip(middle_edge, cell.color, edge, cell.color)
	terrain.add_triangle(center_left, middle_edge.v1, middle_edge.v2)
	terrain.add_triangle_color1(cell.color)
	terrain.add_quad(center_left, center, middle_edge.v2, middle_edge.v3)
	terrain.add_quad_color1(cell.color)
	terrain.add_quad(center, center_right, middle_edge.v3, middle_edge.v4)
	terrain.add_quad_color1(cell.color)
	terrain.add_triangle(center_right, middle_edge.v4, middle_edge.v5)
	terrain.add_triangle_color1(cell.color)

func triangulate_with_river_begin_or_end(var cell: HexCell, var direction: int, var edge: EdgeVertices) -> void:
	var center = cell.center
	var middle_edge = EdgeVertices.new(center.linear_interpolate(edge.v1, 0.5), center.linear_interpolate(edge.v5, 0.5))
	middle_edge.v3.y = edge.v3.y
	terrain.add_edge_strip(middle_edge, cell.color, edge, cell.color)
	terrain.add_edge_fan(center, middle_edge, cell.color)
	var reversed = cell.has_incoming_river
	triangulate_river_quad(middle_edge.v1, middle_edge.v5, edge.v1, edge.v5, cell.river_surface_elevation(), 0.6, reversed)
	center.y = cell.river_surface_elevation()
	middle_edge.v2.y = cell.river_surface_elevation()
	middle_edge.v4.y = cell.river_surface_elevation()
	river.add_triangle(center, middle_edge.v2, middle_edge.v4)
	if reversed:
		river.add_triangle_uv(Vector2(0.5, 0.4), Vector2(0.0, 0.6), Vector2(1.0, 0.6))
	else:
		river.add_triangle_uv(Vector2(0.5, 0.4), Vector2(1.0, 0.2), Vector2(0.0, 0.2))


func triangulate_adjacent_to_river(var cell: HexCell, var direction: int, var edge: EdgeVertices) -> void:
	var center = cell.center
	#The center should be offseted to acomodate flowing river 
	if cell.has_river_through_edge(HexDirection.next(direction)):
		if cell.has_river_through_edge(HexDirection.previous(direction)):
			#Direction inside curved river
			center += HexMetrics.get_solid_middle_corner(direction) * (0.5 * HexMetrics.inner_to_outer)
		elif cell.has_river_through_edge(HexDirection.previous2(direction)):
			#Direction along straight river
			center += HexMetrics.get_first_solid_corner(direction) * 0.25
	elif cell.has_river_through_edge(HexDirection.previous(direction)) and cell.has_river_through_edge(HexDirection.next2(direction)):
			#Direction along straight river
			center += HexMetrics.get_second_solid_corner(direction) * 0.25
	#Direction inside sharp curved river are fine
	var middle_edge = EdgeVertices.new(center.linear_interpolate(edge.v1, 0.5), center.linear_interpolate(edge.v5, 0.5))
	terrain.add_edge_strip(middle_edge, cell.color, edge, cell.color)
	terrain.add_edge_fan(center, middle_edge, cell.color)

func triangulate_river_quad(var v1: Vector3, var v2: Vector3, var v3: Vector3, var v4: Vector3, var elevation: float, var v_offset: float, var reversed: bool) -> void:
	v1.y = elevation
	v2.y = elevation
	v3.y = elevation
	v4.y = elevation
	river.add_quad(v1, v2, v3, v4)
	if reversed:
		river.add_quad_uvf(1.0, 0.0, v_offset, v_offset + 0.2)
	else:
		river.add_quad_uvf(0.0, 1.0, 0.8 - v_offset, 0.6 - v_offset)

func triangulate_river_quad2(var v1: Vector3, var v2: Vector3, var elevation1: float, var v3: Vector3, var v4: Vector3, var elevation2: float, var v_offset: float, var reversed: bool) -> void:
	v1.y = elevation1
	v2.y = elevation1
	v3.y = elevation2
	v4.y = elevation2
	river.add_quad(v1, v2, v3, v4)
	if reversed:
		river.add_quad_uvf(1.0, 0.0, v_offset, v_offset + 0.2)
	else:
		river.add_quad_uvf(0.0, 1.0, 0.8 - v_offset, 0.6 - v_offset)

