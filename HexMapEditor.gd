extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func edit_cell(var cell: HexCell) -> void:
	cell.color = color
	if edit_elevation:
#		cell.elevation = elevation_value
		cell.set_elevation(elevation_value)

var color := Color.white

func _on_selected_color_change(index):
	match index:
		0:
			color = Color.brown
		1:
			color = Color.white
		2:
			color = Color.yellow
		3:
			color = Color.green
		4:
			color = Color.blue
	pass # Replace with function body.

var edit_elevation := false
var elevation_value : int

func _on_elevation_value_changed(value):
	elevation_value = int(value)

func _on_edit_elevation_toggled(button_pressed):
	edit_elevation = button_pressed
