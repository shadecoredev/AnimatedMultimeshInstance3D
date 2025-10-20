extends Node3D

func draw_ray(pos1: Vector3, pos2: Vector3, color = Color.WHITE_SMOKE, persist_ms = -1.0):
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var mesh_material := ORMMaterial3D.new()

	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, mesh_material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()

	mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_material.albedo_color = color

	return await draw_cleanup(mesh_instance, persist_ms)
	
func draw_cleanup(mesh_instance: MeshInstance3D, persist_ms: float):
	add_child(mesh_instance)
	if persist_ms == 1:
		await get_tree().physics_frame
		mesh_instance.queue_free()
	elif persist_ms > 0:
		await get_tree().create_timer(persist_ms).timeout
		mesh_instance.queue_free()
	else:
		return mesh_instance
	

func clear():
	for child in get_children():
		child.queue_free()
