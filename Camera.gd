extends Spatial

onready var camera_swivel = $Swivel
onready var camera_stick = $Swivel/Stick
onready var camera = $Swivel/Stick/Camera

var zoom = 1.0
var zoom_steps = 10
var stick_min_zoom = 50
var stick_max_zoom = 150
var stick_zoom_step = (stick_max_zoom - stick_min_zoom) / zoom_steps
var swivel_min_zoom = -90
var swivel_max_zoom = -40
var swivel_zoom_step = (swivel_max_zoom - swivel_min_zoom) / zoom_steps


func _input(_event):
	if Input.is_action_pressed("ui_left")  :
		translation.x -= 10
	
	if Input.is_action_pressed("ui_right")  :
		translation.x += 10
	
	if Input.is_action_pressed("ui_up")  :
		translation.z -= 10

	if Input.is_action_pressed("ui_down")  :
		translation.z += 10
	
#	if Input.is_action_pressed("rotate_left"):
##		print(camera_base.rotation_degrees.y)
#		rotation_degrees.y -= 10
#
#	if Input.is_action_pressed("rotate_right"):
##		print(camera_base.rotation_degrees.y)
#		rotation_degrees.y += 10

func camera_zoom_out( ) -> void:
	var aux_stick_zoom = camera_stick.translation.z + stick_zoom_step
	aux_stick_zoom = clamp( aux_stick_zoom, stick_min_zoom, stick_max_zoom )
	camera_stick.translation.z = aux_stick_zoom
	var aux_swivel_zoom = camera_swivel.rotation_degrees.x - swivel_zoom_step
	aux_swivel_zoom = clamp( aux_swivel_zoom, swivel_min_zoom, swivel_max_zoom )
	camera_swivel.rotation_degrees.x = aux_swivel_zoom

func camera_zoom_in( ) -> void:
	var aux_stick_zoom = camera_stick.translation.z - stick_zoom_step
	aux_stick_zoom = clamp( aux_stick_zoom, stick_min_zoom, stick_max_zoom )
	camera_stick.translation.z = aux_stick_zoom
	var aux_swivel_zoom = camera_swivel.rotation_degrees.x + swivel_zoom_step
	aux_swivel_zoom = clamp( aux_swivel_zoom, swivel_min_zoom, swivel_max_zoom )
	camera_swivel.rotation_degrees.x = aux_swivel_zoom

func _unhandled_input( event : InputEvent ) -> void:
#	if event.is_action_pressed( "zoom_in" ):
#		camera_zoom_in( )
#	elif event.is_action_pressed( "zoom_out" ):
#		camera_zoom_out( )
	pass

