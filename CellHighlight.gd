extends MeshInstance

func set_outline_color( var color : Color ) -> void:
	mesh.material.set_shader_param("outline_color", color)

