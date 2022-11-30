extends Node

var sampler : OpenSimplexNoise

func _ready():
	sampler = OpenSimplexNoise.new()
	sampler.seed = 42424242
	sampler.octaves = 4
	sampler.persistence = 0.8

func sample_3d(var position: Vector3) -> Vector3:
	return Vector3( sampler.get_noise_3d(position.x, position.y, position.z), sampler.get_noise_3d(position.y, position.z, position.x), sampler.get_noise_3d(position.z, position.x, position.y) )
