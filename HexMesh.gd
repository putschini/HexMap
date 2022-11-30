tool
extends StaticBody

class_name HexMesh

onready var mesh_instance = $MeshInstance
onready var collision_shape = $CollisionShape

var surface_tool : SurfaceTool
var material : Material

var vertices := PoolVector3Array()
var colors := PoolColorArray()

func _ready():
	material = SpatialMaterial.new()
	material.vertex_color_use_as_albedo = true

func triangulate( var cells : Array ) -> void:
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
	var first_solid_corner = center + HexMetrics.get_first_solid_corner(direction)
	var second_solid_corner = center + HexMetrics.get_second_solid_corner(direction)

	add_triangle( center, first_solid_corner, second_solid_corner )
	add_triangle_color(cell.color, cell.color, cell.color)
	# Only triangulate half the connection because connection go from cell solid corner to neighbor solid corner
	if direction <= HexDirection.SE:
		triangulate_connection( cell, direction, first_solid_corner, second_solid_corner )

func triangulate_connection( var cell : HexCell, var direction : int, var first_solid_corner : Vector3, var second_solid_corner : Vector3 ) -> void:
	var neighbor = cell.neighbors[direction]
	if neighbor == null:
		return

	var blend_bridge = HexMetrics.get_blend_bridge(direction)
	var neighbor_elevation_offset = HexMetrics.get_elevation_offset(neighbor.elevation - cell.elevation) 
	var first_bridge_corner = first_solid_corner + blend_bridge + neighbor_elevation_offset
	var second_bridge_corner = second_solid_corner + blend_bridge + neighbor_elevation_offset

	# Rectangle blending region between hexagons
	if cell.get_edge_type(direction) == HexEdgeType.Slop:
		triangulate_slop_edge(first_solid_corner, second_solid_corner, cell, first_bridge_corner, second_bridge_corner, neighbor)
	else:
		add_quad( first_solid_corner, second_solid_corner, first_bridge_corner, second_bridge_corner )
		add_quad_color2(cell.color, neighbor.color)

	var next_neighbor = cell.neighbors[HexDirection.next(direction)]
	# Only add the triangle connection in two direction, to not produce overlaping triangles
	if direction <= HexDirection.E and next_neighbor != null:
		var next_neighbor_bridge_corner = second_solid_corner + HexMetrics.get_blend_bridge( HexDirection.next(direction) ) + HexMetrics.get_elevation_offset(next_neighbor.elevation - cell.elevation)

		#Ajust cells so the triangulation becomes easier, always triangulate from the bottom to the left and right
		if cell.elevation <= neighbor.elevation:
			if cell.elevation <= next_neighbor.elevation:
#				print("cell.elevation <= next_neighbor.elevation")
				triangulate_corner(second_solid_corner, cell, second_bridge_corner, neighbor, next_neighbor_bridge_corner, next_neighbor)
			else:
#				print("ELSEcell.elevation <= next_neighbor.elevation")
				triangulate_corner(next_neighbor_bridge_corner, next_neighbor, second_solid_corner, cell, second_bridge_corner, neighbor)
		elif neighbor.elevation <= next_neighbor.elevation:
#			print("elif neighbor.elevation <= next_neighbor.elevation:")
			triangulate_corner(second_bridge_corner, neighbor, next_neighbor_bridge_corner, next_neighbor, second_solid_corner, cell)
		else:
#			print("else")
			triangulate_corner(next_neighbor_bridge_corner, next_neighbor, second_solid_corner, cell, second_bridge_corner, neighbor)
#		add_triangle( second_solid_corner, second_bridge_corner, next_neighbor_bridge_corner )
#		add_triangle_color( cell.color, neighbor.color, next_neighbor.color )

func triangulate_slop_edge( var left_begin_edge: Vector3, var right_begin_edge: Vector3, var begin_cell: HexCell,
							var left_end_edge: Vector3, var right_end_edge: Vector3, var end_cell: HexCell ) -> void:
	var left_next_edge = HexMetrics.terrace_lerp_interpolation(left_begin_edge, left_end_edge, 1)
	var right_next_edge = HexMetrics.terrace_lerp_interpolation(right_begin_edge, right_end_edge, 1)
	var next_color = HexMetrics.tearrace_lerp_color_interpolation(begin_cell.color, end_cell.color, 1)
	add_quad(left_begin_edge, right_begin_edge, left_next_edge, right_next_edge)
	add_quad_color2(begin_cell.color, next_color)
	for i in range(2, HexMetrics.terrace_steps):
		var left_aux_edge = left_next_edge
		var right_aux_edge = right_next_edge
		var aux_color = next_color
		left_next_edge = HexMetrics.terrace_lerp_interpolation(left_begin_edge, left_end_edge, i)
		right_next_edge = HexMetrics.terrace_lerp_interpolation(right_begin_edge, right_end_edge, i)
		next_color = HexMetrics.tearrace_lerp_color_interpolation(begin_cell.color, end_cell.color, i)
		add_quad(left_aux_edge, right_aux_edge, left_next_edge, right_next_edge)
		add_quad_color2(aux_color, next_color)
#	add_quad( left_begin_edge, right_begin_edge, left_end_edge, right_end_edge)
#	add_quad_color2(begin_cell.color, end_cell.color)
	add_quad(left_next_edge, right_next_edge, left_end_edge, right_end_edge)
	add_quad_color2(next_color, end_cell.color)

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
			add_triangle( bottom_edge, left_edge, right_edge )
			add_triangle_color( bottom_cell.color, left_cell.color, right_cell.color )
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
				add_triangle( bottom_edge, left_edge, right_edge )
				add_triangle_color( bottom_cell.color, left_cell.color, right_cell.color )
		#Cliff-Flat is only one triangle
		else:
			add_triangle( bottom_edge, left_edge, right_edge )
			add_triangle_color( bottom_cell.color, left_cell.color, right_cell.color )
	pass

#Triangulate corner between cells with 1 elevation difference
#Starts from the triangule in the top/bottom corner
func triangulate_slop_corner(var begin_edge: Vector3, var begin_cell: HexCell, var left_edge: Vector3, var left_cell: HexCell, var right_edge: Vector3, var right_cell: HexCell) -> void:
	var left_next_edge = HexMetrics.terrace_lerp_interpolation(begin_edge, left_edge, 1)
	var right_next_edge = HexMetrics.terrace_lerp_interpolation(begin_edge, right_edge, 1)
	var left_next_color = HexMetrics.tearrace_lerp_color_interpolation(begin_cell.color, left_cell.color, 1)
	var right_next_color = HexMetrics.tearrace_lerp_color_interpolation(begin_cell.color, right_cell.color, 1)

	add_triangle(begin_edge, left_next_edge, right_next_edge)
	add_triangle_color(begin_cell.color, left_next_color, right_next_color)
	
	for i in range(2, HexMetrics.terrace_steps):
		var left_aux_edge = left_next_edge
		var right_aux_edge = right_next_edge
		var left_aux_color = left_next_color
		var right_aux_color = right_next_color
		left_next_edge = HexMetrics.terrace_lerp_interpolation(begin_edge, left_edge, i)
		right_next_edge = HexMetrics.terrace_lerp_interpolation(begin_edge, right_edge, i)
		left_next_color = HexMetrics.tearrace_lerp_color_interpolation(begin_cell.color, left_cell.color, i)
		right_next_color = HexMetrics.tearrace_lerp_color_interpolation(begin_cell.color, right_cell.color, i)
		add_quad(left_aux_edge, right_aux_edge, left_next_edge, right_next_edge)
		add_quad_color(left_aux_color, right_aux_color, left_next_color, right_next_color)

	add_quad(left_next_edge, right_next_edge, left_edge, right_edge)
	add_quad_color(left_next_color, right_next_color, left_cell.color, right_cell.color)

#Triangulate corner between a slop and a cliff
#Create a boundary line because diffence between slop and cliff triangulations
func triangulate_slop_cliff_corner(var begin_edge: Vector3, var begin_cell: HexCell, var left_edge: Vector3, var left_cell: HexCell, var right_edge: Vector3, var right_cell: HexCell) -> void:
	var boundary_ratio = abs(1.0 / (right_cell.elevation - begin_cell.elevation))
	var boundary_edge = begin_edge.linear_interpolate(right_edge, boundary_ratio)
	var boundary_color = begin_cell.color.linear_interpolate(right_cell.color, boundary_ratio)
	#Left slop corner
	triangulate_slop_boundary_corner( begin_edge, begin_cell, left_edge, left_cell, boundary_edge, boundary_color )
	#The opposite edge can be a slop or a cliff
	if left_cell.get_cell_edge_type(right_cell) == HexEdgeType.Slop:
		triangulate_slop_boundary_corner(left_edge, left_cell, right_edge, right_cell, boundary_edge, boundary_color)
	else:
		add_triangle(left_edge, right_edge, boundary_edge)
		add_triangle_color(left_cell.color, right_cell.color, boundary_color)

#Triangulate corner between a cliff and a slop
#Create a boundary line because diffence between slop and cliff triangulations
func triangulate_cliff_slop_corner(var begin_edge: Vector3, var begin_cell: HexCell, var left_edge: Vector3, var left_cell: HexCell, var right_edge: Vector3, var right_cell: HexCell) -> void:
	var boundary_ratio = abs(1.0 / (left_cell.elevation - begin_cell.elevation))
	var boundary_edge = begin_edge.linear_interpolate(left_edge, boundary_ratio)
	var boundary_color = begin_cell.color.linear_interpolate(left_cell.color, boundary_ratio)
	#Left slop corner
	triangulate_slop_boundary_corner(right_edge, right_cell, begin_edge, begin_cell, boundary_edge, boundary_color )
	#The opposite edge can be a slop or a cliff
	if left_cell.get_cell_edge_type(right_cell) == HexEdgeType.Slop:
		triangulate_slop_boundary_corner(left_edge, left_cell, right_edge, right_cell, boundary_edge, boundary_color)
	else:
		add_triangle(left_edge, right_edge, boundary_edge)
		add_triangle_color(left_cell.color, right_cell.color, boundary_color)

#Triangulate slop corner to boundary edge
func triangulate_slop_boundary_corner(var begin_edge: Vector3, var begin_cell: HexCell, var left_edge: Vector3, var left_cell: HexCell, var boundary_edge: Vector3, var boundary_color: Color) -> void:
	var left_next_edge = HexMetrics.terrace_lerp_interpolation(begin_edge, left_edge, 1)
	var left_next_color = HexMetrics.tearrace_lerp_color_interpolation(begin_cell.color, left_cell.color, 1)

	add_triangle(begin_edge, left_next_edge, boundary_edge)
	add_triangle_color(begin_cell.color, left_next_color, boundary_color)
	for i in range(2, HexMetrics.terrace_steps):
		var left_aux_edge = left_next_edge
		var left_aux_color = left_next_color
		left_next_edge = HexMetrics.terrace_lerp_interpolation(begin_edge, left_edge, i)
		left_next_color = HexMetrics.tearrace_lerp_color_interpolation(begin_cell.color, left_cell.color, i)
		add_triangle(left_aux_edge, left_next_edge, boundary_edge)
		add_triangle_color(left_aux_color, left_next_color, boundary_color)

	add_triangle(left_next_edge, left_edge, boundary_edge)
	add_triangle_color(left_next_color, left_cell.color, boundary_color)

func add_triangle( var v1 : Vector3, var  v2 : Vector3, var  v3 : Vector3 ) -> void:
	vertices.push_back(v1);
	vertices.push_back(v2);
	vertices.push_back(v3);

func add_triangle_color( var color1 : Color, var color2 : Color, var color3 : Color ) -> void:	
	colors.push_back(color1)
	colors.push_back(color2)
	colors.push_back(color3)

func add_quad( var v1 : Vector3, var  v2 : Vector3, var  v3 : Vector3, var  v4 : Vector3 ) -> void:
	vertices.push_back(v1);
	vertices.push_back(v3);
	vertices.push_back(v2);

	vertices.push_back(v2);
	vertices.push_back(v3);
	vertices.push_back(v4);

func add_quad_color( var c1 : Color, var c2 : Color, var c3 : Color, var c4 : Color ) -> void:
	colors.push_back( c1 )
	colors.push_back( c3 )
	colors.push_back( c2 )

	colors.push_back( c2 )
	colors.push_back( c3 )
	colors.push_back( c4 )

func add_quad_color2( var c1 : Color, var c2 : Color ) -> void:
	add_quad_color(c1, c1, c2, c2)

func commit_mesh( ) -> void:
	if vertices.empty():
		return
		
#	print(vertices.size() / 36)
	surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.set_material(material)
#	print( vertices.size() )
#	print( uvs.size() )
#	print( uvs2.size() )
	surface_tool.add_uv( Vector2(1,1) )
	for i in range( 0, vertices.size() ):
		surface_tool.add_normal(Vector3(0, 0, 1))
#		surface_tool.add_uv( Vector2( vertices[i].x, vertices[i].z ) )
		surface_tool.add_color(colors[i])
		surface_tool.add_vertex(vertices[i])
#		print(vertices[i])
	surface_tool.index()
	surface_tool.generate_normals()
	surface_tool.generate_tangents()

	mesh_instance.mesh = surface_tool.commit()
#	mesh_instance.show()
	
	collision_shape.set_shape( mesh_instance.mesh.create_trimesh_shape() )
	collision_shape.show()
#	mesh_instance.cast_shadow = cast_shadow
	
	vertices = PoolVector3Array()
	colors = PoolColorArray()
