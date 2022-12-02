extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func edit_cell(var cell: HexCell) -> void:
	if cell:
		if edit_color:
			cell.set_color(color)
		if edit_elevation:
			cell.set_elevation(elevation_value)
		if river_edit_value == 2:
			cell.remove_river()
		if road_edit_value == 2:
			cell.remove_roads()

func edit_cell_drag(var cell: HexCell, var direction: int) -> void:
	if river_edit_value == 1:
		cell.set_outgoing_river(direction)
	elif road_edit_value == 1:
		cell.add_road(direction)

var edit_color := false
var color := Color.white

func _on_selected_color_change(index):
	edit_color = true
	match index:
		0:
			edit_color = false
		1:
			color = Color.white
		2:
			color = Color.yellow
		3:
			color = Color.green
		4:
			color = Color.blue

var edit_elevation := false
var elevation_value : int

func _on_elevation_value_changed(value):
	elevation_value = int(value)

func _on_edit_elevation_toggled(button_pressed):
	edit_elevation = button_pressed

var brush_size := 0

func _on_brush_size_value_changed(value):
	brush_size = value

# 0: do nothing, 1: add river, 2: remove river
var river_edit_value := 0

func _on_river_item_selected(index):
	river_edit_value = index

# 0: do nothing, 1: add river, 2: remove river
var road_edit_value := 0

func _on_road_item_selected(index):
	road_edit_value = index
