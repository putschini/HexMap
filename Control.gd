extends Spatial

onready var grid = $HexGrid
onready var map_editor = $HexMapEditor

func _input(event):
	if event.is_action_pressed("mouse_left_click"):
		# TODO: MOVE TO CAMERA SCENE PROBABLY
		var ray_begin = $Camera.camera.project_ray_origin( event.position )
#		var ray = RayCast.new()
		var ray_end = ray_begin + $Camera.camera.project_ray_normal( event.position ) * 200
		var intersection = get_world().direct_space_state.intersect_ray(ray_begin, ray_end)
		if not intersection.empty():
			print(intersection)
			var coordinates = HexMetrics.hexcoord_from_position(intersection.position)
			print( coordinates.xyz())
			var index = coordinates.x + coordinates.z * grid.width + coordinates.z / 2
			print( index )
			var cell = grid.cells[index]
			map_editor.edit_cell(cell)
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
			grid.update()
