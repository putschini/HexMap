extends Node

class_name EdgeVertices

var v1 : Vector3
var v2 : Vector3
var v3 : Vector3
var v4 : Vector3

func _init(var corner1: Vector3, var corner2 : Vector3 ) -> void:
	v1 = corner1
	v2 = corner1.linear_interpolate(corner2, 1.0/3.0)
	v3 = corner1.linear_interpolate(corner2, 2.0/3.0)
	v4 = corner2
