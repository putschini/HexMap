class_name HexCoordinate

var x := 0
var y := 0
var z := 0

func _init( var xn: int, var zn: int ) -> void:
	x = xn
	z = zn
	y = -xn -zn
#	print(Vector3(x, y, z))

func xz() -> Vector2:
	return Vector2( x, z )

func xyz() -> Vector3:
	return Vector3(x, y, z)

func to_string( ) -> String:
#	return "(" + str(x) + "," + str(z) + ")"
	return "(" + str(x) + "," + str(y) + "," + str(z) + ")"
