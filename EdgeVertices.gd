extends Node

class_name EdgeVertices

var v1 : Vector3
var v2 : Vector3
var v3 : Vector3
var v4 : Vector3
var v5 : Vector3

func _init(var corner1: Vector3, var corner2 : Vector3, var step: float = 0.25 ) -> void:
	v1 = corner1
	v2 = corner1.linear_interpolate(corner2, step)
	v3 = corner1.linear_interpolate(corner2, 0.5)
	v4 = corner1.linear_interpolate(corner2, 1 - step)
	v5 = corner2
