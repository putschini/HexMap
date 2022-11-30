class_name HexEdgeType

enum{ Flat, Slop, Cliff }

static func get_edge_type(var elevation1: int, var elevation2: int):
	if elevation1 == elevation2:
		return Flat
	if abs(elevation1 - elevation2) == 1:
		return Slop
	return Cliff
