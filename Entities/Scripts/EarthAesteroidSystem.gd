extends Node3D

@onready var earth = %earth
@onready var commet = %commet
@onready var camera_3d = %Camera3D

#region comet trajectory parameters
var major_axis = Vector3(1, 1, -1)
var minor_axis = Vector3(-1, -1, 1)
var time: float = 0.0
var frequency: float = 0.1 # cycles per second
#endregion

#region path trail parameters
var trail_points: Array[Vector3] = []
var max_trail_points: int =50
var trail_update_interval: float = 0.05 # seconds between trail point updates
var last_trail_update: float = 0.0
var trail_mesh_instance: MeshInstance3D
var trail_material: StandardMaterial3D
var trail_width: float = 0.01  # Trail thickness - adjust this value!
#endregion

func _ready():
	major_axis = $"Marker3D".position
	minor_axis = $"Marker3D2".position
	
	# Setup trail visual
	#setup_trail()

func setup_trail():
	# Create MeshInstance3D for the trail
	trail_mesh_instance = MeshInstance3D.new()
	add_child(trail_mesh_instance)
	
	# Create material for the trail
	trail_material = StandardMaterial3D.new()
	trail_material.albedo_color = Color(0.8, 0.4, 1.0, 0.7)  # Purple with transparency
	trail_material.flags_transparent = true
	trail_material.flags_unshaded = true
	trail_material.vertex_color_use_as_albedo = true
	trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Show both sides
	trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	trail_mesh_instance.material_override = trail_material

func _process(delta):
	var pos = major_axis * cos(2 * PI * frequency * time) + minor_axis * sin(2 * PI * frequency * time)
	commet.position = pos
	
	camera_3d.position = Vector3(5 * cos(TAU * 0.005 * time), 0, 5 * sin(TAU * 0.005 * time))
	camera_3d.look_at(Vector3.ZERO)
	
	
	time += delta

#
#func update_trail(current_pos: Vector3, delta: float):
	#last_trail_update += delta
	#
	## Add new trail point at intervals
	#if last_trail_update >= trail_update_interval:
		#trail_points.append(current_pos)
		#last_trail_update = 0.0
		#
		## Remove old points if we exceed max
		#if trail_points.size() > max_trail_points:
			#trail_points.pop_front()
		#
		## Update the trail mesh
		#create_trail_mesh()
#
#func create_trail_mesh():
	#if trail_points.size() < 2:
		#return
	#
	#var arrays = []
	#arrays.resize(Mesh.ARRAY_MAX)
	#
	#var vertices: PackedVector3Array = []
	#var colors: PackedColorArray = []
	#var indices: PackedInt32Array = []
	#var normals: PackedVector3Array = []
	#var uvs: PackedVector2Array = []
	#
	#var trail_width = self.trail_width  # Use the class variable
	#
	## Create thick trail using quads (triangles)
	#for i in range(trail_points.size() - 1):
		#var start_pos = trail_points[i]
		#var end_pos = trail_points[i + 1]
		#
		## Calculate direction and perpendicular vectors
		#var direction = (end_pos - start_pos).normalized()
		## Use a fixed up vector instead of camera-relative perpendicular for debugging
		#var up = Vector3.UP
		#var perpendicular = direction.cross(up).normalized() * trail_width
		#
		## If direction is parallel to up, use a different reference
		#if abs(direction.dot(up)) > 0.99:
			#perpendicular = direction.cross(Vector3.RIGHT).normalized() * trail_width
		#
		## Calculate alpha based on position in trail (fade out older points)
		#var alpha_start = float(i) / float(trail_points.size() - 1)
		#var alpha_end = float(i + 1) / float(trail_points.size() - 1)
		#
		## Create quad vertices (4 vertices per segment)
		#var base_vertex_index = vertices.size()
		#
		## Start quad vertices
		#vertices.append(start_pos - perpendicular)  # Bottom left
		#vertices.append(start_pos + perpendicular)  # Top left
		#vertices.append(end_pos + perpendicular)    # Top right
		#vertices.append(end_pos - perpendicular)    # Bottom right
		#
		## Add colors (fade from transparent to opaque)
		#var start_color = Color(0.8, 0.4, 1.0, alpha_start * 0.8)
		#var end_color = Color(0.8, 0.4, 1.0, alpha_end * 0.8)
		#
		#colors.append(start_color)
		#colors.append(start_color)
		#colors.append(end_color)
		#colors.append(end_color)
		#
		## Add normals (pointing upward for simplicity)
		#var normal = Vector3.UP
		#normals.append(normal)
		#normals.append(normal)
		#normals.append(normal)
		#normals.append(normal)
		#
		## Add UVs
		#uvs.append(Vector2(0, 0))
		#uvs.append(Vector2(1, 0))
		#uvs.append(Vector2(1, 1))
		#uvs.append(Vector2(0, 1))
		#
		## Create two triangles for the quad
		## First triangle
		#indices.append(base_vertex_index)
		#indices.append(base_vertex_index + 1)
		#indices.append(base_vertex_index + 2)
		#
		## Second triangle
		#indices.append(base_vertex_index)
		#indices.append(base_vertex_index + 2)
		#indices.append(base_vertex_index + 3)
	#
	#arrays[Mesh.ARRAY_VERTEX] = vertices
	#arrays[Mesh.ARRAY_COLOR] = colors
	#arrays[Mesh.ARRAY_INDEX] = indices
	#arrays[Mesh.ARRAY_NORMAL] = normals
	#arrays[Mesh.ARRAY_TEX_UV] = uvs
	#
	#var mesh = ArrayMesh.new()
	#mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	#
	#trail_mesh_instance.mesh = mesh
#
## Optional: Add function to clear trail
#func clear_trail():
	#trail_points.clear()
	#if trail_mesh_instance:
		#trail_mesh_instance.mesh = null
#
## Optional: Add function to change trail properties
#func set_trail_properties(max_points: int, update_interval: float, color: Color, width: float = 0.1):
	#max_trail_points = max_points
	#trail_update_interval = update_interval
	#trail_width = width
	#if trail_material:
		#trail_material.albedo_color = color
#
## Optional: Set trail width separately
#func set_trail_width(width: float):
	#trail_width = width
