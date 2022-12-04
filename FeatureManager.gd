extends Spatial

class_name FeatureManager

onready var wall : HexMesh = $Wall

func _ready():
	wall.setup(false, true, false, false)

func add_wall(var near: EdgeVertices, var near_cell: HexCell, var far: EdgeVertices, var far_cell: HexCell, var has_road: bool, var has_river: bool ) -> void:
	if near_cell.walled != far_cell.walled and HexEdgeType.get_edge_type(near_cell.elevation, far_cell.elevation) != HexEdgeType.Cliff: # and not near_cell.is_under_water() and not far_cell.is_under_water():
		add_wall_segment(near.v1, near.v2, far.v1, far.v2)
		if has_road or has_river:
			add_wall_cap(near.v2, near.v4)
			add_wall_cap(far.v2, far.v4)
		else:
			add_wall_segment(near.v2, near.v3, far.v2, far.v3)
			add_wall_segment(near.v3, near.v4, far.v3, far.v4)
		add_wall_segment(near.v4, near.v5, far.v4, far.v5)
	pass

func add_wall_segment(var near_left: Vector3, var near_right: Vector3, var far_left: Vector3, var far_right: Vector3) -> void:
	near_left = HexMetrics.perturb(near_left)
	near_right = HexMetrics.perturb(near_right)
	far_left = HexMetrics.perturb(far_left)
	far_right = HexMetrics.perturb(far_right)

	var left = HexMetrics.wall_lerp(near_left, far_left)
	var right = HexMetrics.wall_lerp(near_right, far_right)
	
	
	var left_thickness_offset = HexMetrics.wall_thickness_offset(near_left, far_left)
	var right_thickness_offset = HexMetrics.wall_thickness_offset(near_right, far_right)
	
	var v1 = left - left_thickness_offset
	var v2 = right - right_thickness_offset
	var v3 = left - left_thickness_offset + Vector3(0.0, HexMetrics.wall_height, 0.0)
	var v4 = right - right_thickness_offset + Vector3(0.0, HexMetrics.wall_height, 0.0)
	wall.add_quad_unperturbed(v1, v2, v3, v4)
	wall.add_quad_color1(Color.red)
	var t1 = v3
	var t2 = v4

	v1 = left + left_thickness_offset
	v2 = right + right_thickness_offset
	v3 = left + left_thickness_offset + Vector3(0.0, HexMetrics.wall_height, 0.0)
	v4 = right + right_thickness_offset + Vector3(0.0, HexMetrics.wall_height, 0.0)
	wall.add_quad_unperturbed(v2, v1, v4, v3)
	wall.add_quad_color1(Color.red)

	wall.add_quad_unperturbed(t1, t2, v3, v4)
	wall.add_quad_color1(Color.red)

func add_wall_cap(var near: Vector3, var far: Vector3) -> void:
	near = HexMetrics.perturb(near)
	far = HexMetrics.perturb(far)
	
	var center = HexMetrics.wall_lerp(near, far)
	var thickness = HexMetrics.wall_thickness_offset(near, far)
	
	var b1 = center - thickness
	var b2 = center + thickness
	var t1 = center - thickness + Vector3(0.0, HexMetrics.wall_height, 0.0)
	var t2 = center + thickness + Vector3(0.0, HexMetrics.wall_height, 0.0)
	wall.add_quad_unperturbed(b1, b2, t1, t2)
	wall.add_quad_color1(Color.red)

#Cornor only exist when one or two cells are walled
func add_wall_corner(var v1: Vector3, c1: HexCell, var v2: Vector3, var c2: HexCell, var v3: Vector3, var c3: HexCell) -> void:
	if c1.walled:
		if c2.walled:
			if not c3.walled:
				add_wall_corner_segment(v3, c3, v1, c1, v2, c2)
		elif c3.walled:
			add_wall_corner_segment(v2, c2, v3, c3, v1, c1)
		else:
			add_wall_corner_segment(v1, c1, v2, c2, v3, c3)
	elif c2.walled:
		if c3.walled:
			add_wall_corner_segment(v1, c1, v2, c2, v3, c3)
		else:
			add_wall_corner_segment(v2, c2, v3, c3, v1, c1)
	elif c3.walled:
		add_wall_corner_segment(v3, c3, v1, c1, v2, c2)

func add_wall_corner_segment(var inside: Vector3, inside_cell: HexCell, var left: Vector3, var left_cell: HexCell, var right: Vector3, var right_cell: HexCell) -> void:
#	if not inside_cell.is_under_water():
	var has_left_wall = HexEdgeType.get_edge_type(inside_cell.elevation, left_cell.elevation) != HexEdgeType.Cliff# and not left_cell.is_under_water()
	var has_right_wall = HexEdgeType.get_edge_type(inside_cell.elevation, right_cell.elevation) != HexEdgeType.Cliff# and not right_cell.is_under_water()
	if has_left_wall:
		if has_right_wall:
			add_wall_segment( inside, inside, left, right )
		elif left_cell.elevation < right_cell.elevation:
			add_wall_cliff_cap(inside, left, right)
		else:
			add_wall_cap(inside, left)
	elif has_right_wall:
		if right_cell.elevation < left_cell.elevation:
			add_wall_cliff_cap(right, inside, left)
		else:
			add_wall_cap(inside, right)

func add_wall_cliff_cap(var near: Vector3, var far: Vector3, var inside_point: Vector3) -> void:
	near = HexMetrics.perturb(near)
	far = HexMetrics.perturb(far)
	inside_point = HexMetrics.perturb(inside_point)
	var inside_point_top = inside_point
	
	var center = HexMetrics.wall_lerp(near, far)
	var thickness = HexMetrics.wall_thickness_offset(near, far)
	
	var b1 = center - thickness
	var b2 = center + thickness
	inside_point.y = center.y
	var t1 = center - thickness + Vector3(0.0, HexMetrics.wall_height, 0.0)
	var t2 = center + thickness + Vector3(0.0, HexMetrics.wall_height, 0.0)
	inside_point_top.y = center.y + HexMetrics.wall_height

	wall.add_quad_unperturbed(b1, inside_point, t1, inside_point_top)
	wall.add_quad_color1(Color.red)
	wall.add_quad_unperturbed(inside_point, b2, inside_point_top, t2)
	wall.add_quad_color1(Color.red)
	wall.add_triangle_unperturbed(t1, t2, inside_point_top)
	wall.add_triangle_color1(Color.red)

func commit_mesh( ) -> void:
	wall.commit_mesh( )

