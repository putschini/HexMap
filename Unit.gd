extends KinematicBody

class_name Unit

var cell

var speed = 14

var height := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	height = $CollisionShape.shape.height * 2#$MeshInstance.mesh.size.y
	pass # Replace with function body.


var path : Array

var speed_move = 10
var velocity = Vector3.ZERO
var next_stop = Vector3.ZERO

func _physics_process(delta):
	if not path.empty():
		if next_stop == Vector3.ZERO:
#			print("Move")
			var next = path.pop_front()
			next_stop = next.center
			var direction = translation.direction_to(next_stop)
#			print(direction)
			$MeshInstance.look_at(translation + direction + Vector3(0,height,0), Vector3.UP)
			velocity.x = direction.x * speed_move
			velocity.z = direction.z * speed_move
	velocity = move_and_slide(velocity, Vector3.UP)
	if translation.distance_to(next_stop) < 0.05:
#		print(translation)
#		print(next_stop)
		translation = next_stop
		velocity = Vector3.ZERO
		next_stop = Vector3.ZERO
	
#		while not path.empty():
#			var next = path.pop_front()
#			self.translation = next.center
	
