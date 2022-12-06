tool
extends StaticBody

class_name HexMesh

onready var mesh_instance = $MeshInstance
onready var collision_shape = $CollisionShape

var surface_tool : SurfaceTool
#TODO: maybe export the material
var material : Material

var vertices := PoolVector3Array()
var uvs := PoolVector2Array()
var colors := PoolColorArray()


var use_collider := false
var use_color := false
var use_uvs := false
var cast_shadow := true

func _ready():
	material = SpatialMaterial.new()
	material.vertex_color_use_as_albedo = true

func setup(var colider: bool, var color: bool, uvs: bool, var shadows: bool ) -> void:
	use_collider = colider
	use_color = color
	use_uvs = uvs
	cast_shadow = shadows

func set_material(var new_material: ShaderMaterial) -> void:
	material = new_material

func set_next_material(var next_material: ShaderMaterial) -> void:
	material.next_pass = next_material
#	material.next_pass(next_material)

func add_triangle( var v1 : Vector3, var  v2 : Vector3, var  v3 : Vector3 ) -> void:
	vertices.push_back(HexMetrics.perturb(v1));
	vertices.push_back(HexMetrics.perturb(v2));
	vertices.push_back(HexMetrics.perturb(v3));

func add_triangle_unperturbed(var v1: Vector3, var v2: Vector3, var v3: Vector3) -> void:
	vertices.push_back(v1);
	vertices.push_back(v2);
	vertices.push_back(v3);

func add_triangle_color( var color1 : Color, var color2 : Color, var color3 : Color ) -> void:	
	colors.push_back(color1)
	colors.push_back(color2)
	colors.push_back(color3)

func add_triangle_color1(var color: Color) -> void:
	add_triangle_color(color, color, color)

func add_triangle_uv(var v1: Vector2, var v2: Vector2, var v3: Vector2) -> void:
	uvs.push_back(v1)
	uvs.push_back(v2)
	uvs.push_back(v3)

func add_quad( var v1 : Vector3, var  v2 : Vector3, var  v3 : Vector3, var  v4 : Vector3 ) -> void:
	vertices.push_back(HexMetrics.perturb(v1));
	vertices.push_back(HexMetrics.perturb(v3));
	vertices.push_back(HexMetrics.perturb(v2));

	vertices.push_back(HexMetrics.perturb(v2));
	vertices.push_back(HexMetrics.perturb(v3));
	vertices.push_back(HexMetrics.perturb(v4));

func add_quad_unperturbed( var v1 : Vector3, var  v2 : Vector3, var  v3 : Vector3, var  v4 : Vector3 ) -> void:
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

func add_quad_color1(var c1: Color) -> void:
	add_quad_color(c1, c1, c1, c1)

func add_quad_color2( var c1 : Color, var c2 : Color ) -> void:
	add_quad_color(c1, c1, c2, c2)

func add_quad_uv(var v1: Vector2, var v2: Vector2, var v3: Vector2, var v4: Vector2) -> void:
	uvs.push_back(v1)
	uvs.push_back(v3)
	uvs.push_back(v2)

	uvs.push_back(v2)
	uvs.push_back(v3)
	uvs.push_back(v4)

func add_quad_uvf(var u_min: float, var u_max: float, var v_min: float, var v_max: float) -> void:
	add_quad_uv(Vector2(u_min, v_min), Vector2(u_max, v_min), Vector2(u_min, v_max), Vector2(u_max, v_max))

func add_edge_fan(var center_vertice: Vector3, var edge: EdgeVertices, var color: Color) -> void:
	add_triangle(center_vertice, edge.v1, edge.v2)
	add_triangle_color1(color)
	add_triangle(center_vertice, edge.v2, edge.v3)
	add_triangle_color1(color)
	add_triangle(center_vertice, edge.v3, edge.v4)
	add_triangle_color1(color)
	add_triangle(center_vertice, edge.v4, edge.v5)
	add_triangle_color1(color)

func add_edge_strip(var left_edge: EdgeVertices, var left_color: Color, var right_edge: EdgeVertices, var right_color: Color) -> void:
	add_quad(left_edge.v1, left_edge.v2, right_edge.v1, right_edge.v2)
	add_quad_color2(left_color, right_color)
	add_quad(left_edge.v2, left_edge.v3, right_edge.v2, right_edge.v3)
	add_quad_color2(left_color, right_color)
	add_quad(left_edge.v3, left_edge.v4, right_edge.v3, right_edge.v4)
	add_quad_color2(left_color, right_color)
	add_quad(left_edge.v4, left_edge.v5, right_edge.v4, right_edge.v5)
	add_quad_color2(left_color, right_color)

func commit_mesh( ) -> void:
	if vertices.empty():
		return
	if use_uvs and vertices.size() != uvs.size():
		print("NOT SAME SIZE")
		print(vertices.size())
		print(uvs.size())
#	print(vertices.size())
#	print(vertices.size() / 36)
	surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.set_material(material)
#	print( vertices.size() )
#	print( uvs.size() )
#	print( uvs2.size() )
	if not use_color:
		surface_tool.add_color(Color.white)
	if not use_uvs:
		surface_tool.add_uv( Vector2(1,1) )
	for i in range( 0, vertices.size() ):
		surface_tool.add_normal(Vector3(0, 0, 1))
#		surface_tool.add_uv( Vector2( vertices[i].x, vertices[i].z ) )
		if use_color:
			surface_tool.add_color(colors[i])
		if use_uvs:
			surface_tool.add_uv(uvs[i])
		surface_tool.add_vertex(vertices[i])
#		print(vertices[i])
	surface_tool.index()
	surface_tool.generate_normals()
	surface_tool.generate_tangents()

	mesh_instance.mesh = surface_tool.commit()
	mesh_instance.cast_shadow = cast_shadow
#	mesh_instance.show()
	if use_collider:
		collision_shape.set_shape( mesh_instance.mesh.create_trimesh_shape() )
		collision_shape.show()
#	mesh_instance.cast_shadow = cast_shadow
	
	vertices = PoolVector3Array()
	colors = PoolColorArray()
	uvs = PoolVector2Array()
