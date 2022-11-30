class_name HexDirection

#enum direction_enum { NE=0, E=1, SE=2, SW=3, W=4, NW=5 }

const NE := 0
const E := 1
const SE := 2
const SW := 3
const W := 4
const NW := 5

#var value : int

#func _init( var direction : int ) -> void:
##	value = direction
#	if direction < NE or direction > NW:
#		print( "ERROR INVALID DIRECTION" )

#func equal( var direction : HexDirection ) -> bool:
#	return direction.value == value

static func oposite( var value : int ) -> int:
	if value < 3:
		return value + 3
	else:
		return value - 3

static func previous( var value : int ) -> int:
	if value == NE:
		return NW
	else:
		return value - 1

static func previous2( var value : int ) -> int:
	var aux_value = value
	aux_value -= 2
	if aux_value < NE:
		aux_value += 6
	return aux_value

static func next( var value : int ) -> int:
	if value == NW:
		return NE
	else:
		return value + 1

static func next2( var value : int ) -> int:
	var aux_value = value
	aux_value += 2
	if aux_value > NW:
		aux_value -= 6
	return aux_value

static func values( ) -> Array:
	return [NE, E, SE, SW, W, NW]
