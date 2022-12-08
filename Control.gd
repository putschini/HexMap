extends Spatial

onready var grid = $HexGrid
onready var map_editor = $HexMapEditor

var last_edited_cell
var is_pressed := false
var drag_direction := -1

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
	last_edited_cell = center_cell

func validate_drag(var current_cell: HexCell) -> void:
	for direction in HexDirection.values():
		if last_edited_cell.neighbors[direction] != null and last_edited_cell.neighbors[direction] == current_cell:
			drag_direction = direction
			return
	drag_direction = -1

var old_cell

func _input(event):
	if event.is_action_pressed("mouse_left_click"):
		var ray_begin = $Camera.camera.project_ray_origin( event.position )
		var ray_end = ray_begin + $Camera.camera.project_ray_normal( event.position ) * 200
		var intersection = get_world().direct_space_state.intersect_ray(ray_begin, ray_end)
		if not intersection.empty():
			var coordinates = HexMetrics.hexcoord_from_position(intersection.position)
			var cell = grid.get_cell(coordinates)
#			cell.enable_highlight(Color.blue)
			print("CELL FOUND")
			if old_cell != null and cell != old_cell:
				grid.find_path( old_cell, cell )
			old_cell = cell
			#grid.find_distances_to(cell)
			grid.update()
#			edit_cells(cell)
#		is_pressed = true
	elif event.is_action_released("mouse_left_click"):
		last_edited_cell = null
		is_pressed = false
	elif is_pressed and event is InputEventMouseMotion:
		var ray_begin = $Camera.camera.project_ray_origin( event.position )
		var ray_end = ray_begin + $Camera.camera.project_ray_normal( event.position ) * 200
		var intersection = get_world().direct_space_state.intersect_ray(ray_begin, ray_end)
		if not intersection.empty():
			var coordinates = HexMetrics.hexcoord_from_position(intersection.position)
			var cell = grid.get_cell(coordinates)
			if cell != last_edited_cell:
				validate_drag(cell)
				if drag_direction > -1:
					map_editor.edit_cell_drag(last_edited_cell, drag_direction)
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
