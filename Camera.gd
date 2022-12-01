extends Spatial

onready var camera_swivel = $Swivel
onready var camera_stick = $Swivel/Stick
onready var camera = $Swivel/Stick/Camera

var zoom = 0.0
var zoom_steps = 10.0
var stick_min_zoom = 30
var stick_max_zoom = 90
var stick_zoom_step = (stick_max_zoom - stick_min_zoom) / zoom_steps
var swivel_min_zoom = -90
var swivel_max_zoom = -45
var swivel_zoom_step = (swivel_max_zoom - swivel_min_zoom) / zoom_steps

#var movement_speed := 100
var move_speed_min_zoom := 100
var move_speed_max_zoom := 300

var rotation_speed := 100

var max_x := (HexMetrics.chunk_count_x * HexMetrics.chunk_size_x - 0.5) * (2.0 * HexMetrics.inner_radius)
var max_z := -(HexMetrics.chunk_count_z * HexMetrics.chunk_size_z - 1) * (1.5 * HexMetrics.outer_radius)
#var 

func _input(event):	
	if event.is_action_pressed( "zoom_in" ):
		camera_zoom_in( )
	elif event.is_action_pressed( "zoom_out" ):
		camera_zoom_out( )

func _process(delta):
	var move_direction := Vector3.ZERO
	move_direction.x += (Input.get_action_strength("move_right") - Input.get_action_strength("move_left"))
	move_direction.z += (Input.get_action_strength("move_back") - Input.get_action_strength("move_foward")) 
	move_direction = move_direction.rotated(Vector3(0,1,0), rotation.y ).normalized()
	var movement_speed = lerp(move_speed_min_zoom, move_speed_max_zoom, zoom)
	var new_position = translation + move_direction * movement_speed * delta
	new_position.x = clamp(new_position.x, 0.0, max_x)
	new_position.z = clamp(new_position.z, max_z, 0.0)
	translation = new_position

	var rotation_delta = (Input.get_action_strength("rotate_left") - Input.get_action_strength("rotate_right") )
	rotation_degrees.y += rotation_delta * rotation_speed * delta

func camera_zoom_out( ) -> void:
	var aux_stick_zoom = camera_stick.translation.z + stick_zoom_step
	aux_stick_zoom = clamp( aux_stick_zoom, stick_min_zoom, stick_max_zoom )
	camera_stick.translation.z = aux_stick_zoom
	var aux_swivel_zoom = camera_swivel.rotation_degrees.x - swivel_zoom_step
	aux_swivel_zoom = clamp( aux_swivel_zoom, swivel_min_zoom, swivel_max_zoom )
	camera_swivel.rotation_degrees.x = aux_swivel_zoom
	zoom += 0.1
	if zoom > 1:
		zoom = 1

func camera_zoom_in( ) -> void:
	var aux_stick_zoom = camera_stick.translation.z - stick_zoom_step
	aux_stick_zoom = clamp( aux_stick_zoom, stick_min_zoom, stick_max_zoom )
	camera_stick.translation.z = aux_stick_zoom
	var aux_swivel_zoom = camera_swivel.rotation_degrees.x + swivel_zoom_step
	aux_swivel_zoom = clamp( aux_swivel_zoom, swivel_min_zoom, swivel_max_zoom )
	camera_swivel.rotation_degrees.x = aux_swivel_zoom
	zoom -= 0.1
	if zoom < 0:
		zoom = 0
#
#func _unhandled_input( event : InputEvent ) -> void:
#	if event.is_action_pressed( "zoom_in" ):
#		camera_zoom_in( )
#	elif event.is_action_pressed( "zoom_out" ):
#		camera_zoom_out( )
#	pass

