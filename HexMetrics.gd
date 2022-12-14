class_name HexMetrics

#Cells per chunk
const chunk_size_x := 5
const chunk_size_z := 5
#Number of chunks
const chunk_count_x := 4
const chunk_count_z := 3

####################### Hexagon Geometry ########################
#################################################################
const outer_to_inner := 0.866025404 # sqrt(3) / 2
const inner_to_outer := 1.0 / outer_to_inner

const outer_radius = 10.0
const inner_radius = outer_radius * outer_to_inner 

const cell_perturb_strength := 0.0 #5.0
const cell_perturb_elevation_strength := 1.5

static func perturb(var position: Vector3) -> Vector3:
	var pertub = Noise.sample_3d(position)
	var ret = Vector3()
	ret.x = position.x + pertub.x * cell_perturb_strength
	ret.y = position.y
	ret.z = position.z + pertub.z * cell_perturb_strength
	return ret

########################## CORNERS ##############################
# Z axis is flip from Unity
const corners := [
	Vector3(0.0, 0.0, -outer_radius),
	Vector3(inner_radius, 0.0, -0.5 * outer_radius),
	Vector3(inner_radius, 0.0, 0.5 * outer_radius),
	Vector3(0.0, 0.0, outer_radius),
	Vector3(-inner_radius, 0.0, 0.5 * outer_radius),
	Vector3(-inner_radius, 0.0, -0.5 * outer_radius),
	Vector3(0.0, 0.0, -outer_radius)]

static func get_first_corner( var direction : int ) -> Vector3:
	return corners[direction]

static func get_second_corner( var direction : int ) -> Vector3:
	return corners[direction + 1]

const solid_factor = 0.8
const blend_factor = 1 - solid_factor

static func get_first_solid_corner( var direction : int ) -> Vector3:
	return corners[direction] * solid_factor

static func get_second_solid_corner( var direction : int ) -> Vector3:
	return corners[direction + 1] * solid_factor

static func get_solid_middle_corner(var direction: int) -> Vector3:
	return (corners[direction] + corners[direction+1]) * (solid_factor * 0.5)

static func get_blend_bridge( var direction : int ) -> Vector3:
	return (corners[direction] + corners[direction + 1]) * blend_factor

########################## COORDINATES ##############################
static func cell_center_from_offset( var x :int, var z :int ) -> Vector3:
	var xn = (x + z * 0.5 - int(z / 2)) * (inner_radius * 2.0)
	var zn = - z * (outer_radius * 1.5)
	return Vector3( xn, 0, zn )

static func cell_coordinate_from_offset( var x : int, var z : int ) -> HexCoordinate:
	return HexCoordinate.new(x - z / 2, z)

static func hexcoord_from_position(var position : Vector3) -> HexCoordinate:
	var x = position.x / (inner_radius * 2.0)
	var y = -x
	
	var offset = -position.z / (outer_radius * 3.0)
	x -= offset
	y -= offset
	
	var ix = round(x)
	var iy = round(y)
	var iz = round(-x -y)
	if ix + iy + iz != 0:
		var dx = abs(x - ix)
		var dy = abs(y - iy)
		var dz = abs(-x -y - iz)
		if dx > dy and dx > dz:
			ix = -iy -iz
		elif dz > dy:
			iz = -ix -iy

	return HexCoordinate.new(ix, iz)

########################## ELEVATION ##############################
const elevation_height = 5

static func get_elevation_offset(var cell_elevation: int) -> Vector3:
	return Vector3(0, cell_elevation * elevation_height, 0)

const terraces_per_slope = 2.0
const terrace_steps = terraces_per_slope * 2.0 + 1.0
const horizontal_terrace_step_size = 1.0 / terrace_steps
const vertical_terrace_step_size = 1.0 / (terraces_per_slope + 1.0)

static func terrace_lerp_interpolation(var a: Vector3, var b: Vector3, var step: float) -> Vector3:
	var horizontal_offset = step * horizontal_terrace_step_size
	var ret = a.linear_interpolate(b, horizontal_offset)
	var vertical_offset = int((step + 1) / 2.0) * vertical_terrace_step_size
	ret.y = a.y + ((b.y - a.y) * vertical_offset)
	return ret

static func tearrace_lerp_color_interpolation(var a: Color, var b: Color, var step: int) -> Color:
	var horizontal_offset = step * horizontal_terrace_step_size
	return a.linear_interpolate(b, horizontal_offset)

static func terrace_lerp_edge_interpolation(var a: EdgeVertices, var b: EdgeVertices, var step: int) -> EdgeVertices:
	var ret = EdgeVertices.new(a.v1, b.v1)
	ret.v1 = terrace_lerp_interpolation(a.v1, b.v1, step)
	ret.v2 = terrace_lerp_interpolation(a.v2, b.v2, step)
	ret.v3 = terrace_lerp_interpolation(a.v3, b.v3, step)
	ret.v4 = terrace_lerp_interpolation(a.v4, b.v4, step)
	ret.v5 = terrace_lerp_interpolation(a.v5, b.v5, step)
	return ret


const river_bed_offset = -1.0
const river_surface_offset = -0.25

const wall_height = 5.0
const wall_thickness = 0.75
const wall_elevation_offset = vertical_terrace_step_size

static func wall_thickness_offset(var near: Vector3, var far: Vector3) -> Vector3:
	var offset := Vector3()
	offset.x = far.x - near.x
	offset.y = 0
	offset.z = far.z - near.z
	return offset.normalized() * (wall_thickness * 0.5)

static func wall_lerp( var near: Vector3, var far: Vector3 ) -> Vector3:
	var result = near
	result.x += (far.x - near.x) * 0.5
	result.z += (far.z - near.z) * 0.5
	var y_offset = wall_elevation_offset if near.y < far.y else (1 - wall_elevation_offset)
	result.y += (far.y - near.y) * y_offset
	return result
