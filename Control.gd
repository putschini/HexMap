extends Spatial

onready var grid = $HexGrid
onready var map_editor = $HexMapEditor

var test_unit := preload("res://TestUnit.tscn")

func _ready():
	grid.add_unit(grid.get_cell(HexCoordinate.new(1,1)), test_unit.instance())

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

var selected_cell : HexCell
var last_searched : HexCell

func get_cell_under_cursor(var cursor_position) -> HexCell:
	var ray_begin = $Camera.camera.project_ray_origin( cursor_position )
	var ray_end = ray_begin + $Camera.camera.project_ray_normal( cursor_position ) * 200
	var intersection = get_world().direct_space_state.intersect_ray(ray_begin, ray_end)
	if not intersection.empty():
		var coordinates = HexMetrics.hexcoord_from_position(intersection.position)
		return grid.get_cell(coordinates)
	return null

func _input(event):
	if event.is_action_pressed("mouse_left_click"):
		var cell = get_cell_under_cursor( event.position )
		if cell != null:
			if map_editor.edit_enabled:
				edit_cells(cell)
			else:
				cell.enable_highlight(Color.green)
				if selected_cell == cell:
					selected_cell = null
				elif selected_cell != null:
					if selected_cell.unit != null and cell.unit == null:
						if not grid.move_unit(selected_cell, cell):
							print("Notice: Path Not found")
					else:
						grid.find_path( selected_cell, cell, 14 )
				else:
					selected_cell = cell
			grid.update()
		is_pressed = true
	elif event.is_action_released("mouse_left_click"):
		last_edited_cell = null
		is_pressed = false
	elif (is_pressed or selected_cell) and event is InputEventMouseMotion:
		if is_pressed and map_editor.edit_enabled:
			var cell = get_cell_under_cursor( event.position )
			if cell != null and cell != last_edited_cell:
				validate_drag(cell)
				if drag_direction > -1:
					map_editor.edit_cell_drag(last_edited_cell, drag_direction)
#				edit_cells(cell)
#		elif selected_cell != null:
#			var cell = get_cell_under_cursor( event.position )
#			if selected_cell != cell and last_searched != cell:
#				grid.find_path( selected_cell, cell, 14 )
#				last_searched = cell
	if event.is_action_pressed("toggle_edit_mode"):
		map_editor.edit_enabled  = !map_editor.edit_enabled
		map_editor.visible = map_editor.edit_enabled
