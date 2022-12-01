extends Spatial

onready var grid = $HexGrid
onready var map_editor = $HexMapEditor

var last_edited_cell

func edit_cells(var center_cell: HexCell) -> void:
	var center_x = center_cell.coordinate.x
	var center_z = center_cell.coordinate.z
	var row = 0
	for z in range(center_z - map_editor.brush_size, center_z + 1):
		for x in range(center_x - row, center_x + map_editor.brush_size + 1):
			map_editor.edit_cell(grid.get_cell(HexCoordinate.new(x, z)))
		row += 1
	row = 0
	for z in range(center_z + map_editor.brush_size, center_z, -1):
		for x in range(center_x - map_editor.brush_size, center_x + row + 1):
			map_editor.edit_cell(grid.get_cell(HexCoordinate.new(x, z)))
		row += 1
#	map_editor.edit_cell(center_cell)

func _input(event):
	if event.is_action_pressed("mouse_left_click"):
		var ray_begin = $Camera.camera.project_ray_origin( event.position )
		var ray_end = ray_begin + $Camera.camera.project_ray_normal( event.position ) * 200
		var intersection = get_world().direct_space_state.intersect_ray(ray_begin, ray_end)
		if not intersection.empty():
#			print(intersection)
			var coordinates = HexMetrics.hexcoord_from_position(intersection.position)
#			print( coordinates.xyz())
			var cell = grid.get_cell(coordinates)
			edit_cells(cell)
#			if cell != last_edited_cell:
#				last_edited_cell = cell
#			var index = coordinates.x + coordinates.z * grid.width + coordinates.z / 2
#			print( index )
#			var cell = grid.cells[index]
#			map_editor.edit_cell(cell)
#			cell.color = Color.magenta
#			cell.color = $HexMapEditor.color

#			print( "Cell pos -> " + cell.coordinate.to_string() )
#			for i in HexDirection.values():
#				if cell.neighbors[i] != null:
#					cell.neighbors[i].color = Color.magenta
#					print( "N -> " + cell.neighbors[i].coordinate.to_string() )
#				else:
#					print( "N -> null")
#			hex_mesh.triangulate( cells )
#			grid.update()
