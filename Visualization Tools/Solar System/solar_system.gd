extends Node3D
@onready var data_container = %DataContainer

var planet_nodes = {}
var time_scale = 1000.0  # Speed up time by 1000x

func _ready():
	# Better distance scales - logarithmic for visibility
	var distance_scales = {
		"Sun": 0.0,
		"Mercury": 1.5,
		"Venus": 2.5,
		"Earth": 3.5,
		"Mars": 4.8,
		"Jupiter": 7.0,
		"Saturn": 10.0,
		"Uranus": 12.5,
		"Neptune": 14.5,
		"Pluto": 16.5
	}
	
	# Moon distance scales (relative to parent planet)
	var moon_distance_scales = {
		"Moon": 0.5,      # Visual distance from Earth
		"Phobos": 0.3,    # Visual distance from Mars
		"Deimos": 0.45    # Visual distance from Mars
	}
	
	# Scale sizes for visibility (smaller than before)
	var size_multiplier = 0.8
	
	# First pass: Create all planets
	for body_name in data_container.celestial_bodies:
		var body_data = data_container.celestial_bodies[body_name]
		if not body_data.has("parent"):  # Only create non-moon bodies first
			var custom_distance = distance_scales.get(body_name, 1.0)
			create_celestial_body(body_name, custom_distance, size_multiplier, 0.0)
	
	# Second pass: Create all moons with proper distances
	for body_name in data_container.celestial_bodies:
		var body_data = data_container.celestial_bodies[body_name]
		if body_data.has("parent"):  # Only create moons
			var moon_distance = moon_distance_scales.get(body_name, 0.4)
			create_celestial_body(body_name, 0.0, size_multiplier, moon_distance)
	
	# Add lighting
	var light = DirectionalLight3D.new()
	light.position = Vector3(0, 5, 5)
	add_child(light)
	light.look_at(Vector3.ZERO)
	light.light_energy = 1.5

func create_celestial_body(body_name: String, distance: float, size_mult: float, moon_distance: float):
	var data = data_container.celestial_bodies[body_name]
	
	# Check if this body orbits a parent planet (moon)
	var parent_body = null
	var is_moon = data.has("parent")
	
	if is_moon:
		var parent_name = data["parent"]
		if planet_nodes.has(parent_name):
			parent_body = planet_nodes[parent_name]["mesh"]
			distance = moon_distance  # Use the provided moon distance
			print("Creating moon: ", body_name, " orbiting ", parent_name, " at distance: ", distance)
		else:
			push_error("Parent planet not found for moon: " + body_name)
			return
	else:
		print("Creating: ", body_name, " at distance: ", distance)
	
	# Create container node for orbit with inclination
	var orbit_node = Node3D.new()
	orbit_node.name = body_name + "_Orbit"
	
	# If it's a moon, attach to parent planet; otherwise attach to main scene
	if parent_body:
		parent_body.add_child(orbit_node)
	else:
		add_child(orbit_node)
	
	# Apply orbital inclination (tilt of orbital plane)
	if data.has("inclination"):
		orbit_node.rotation_degrees.x = data["inclination"]
	
	# Create ellipse path node for eccentricity
	var ellipse_node = Node3D.new()
	ellipse_node.name = body_name + "_Ellipse"
	orbit_node.add_child(ellipse_node)
	
	# Create sphere mesh
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	
	# Make very small objects more visible (minimum size)
	var actual_size = max(data["size"] * size_mult, 0.05)  # Minimum 0.05 units
	
	# Make moons even smaller relative to planets
	if is_moon:
		actual_size = max(data["size"] * size_mult * 2.0, 0.03)  # Moons are bit bigger for visibility
	
	sphere_mesh.radius = actual_size
	sphere_mesh.height = actual_size * 2.0
	sphere_mesh.radial_segments = 64
	sphere_mesh.rings = 32
	mesh_instance.mesh = sphere_mesh
	mesh_instance.name = body_name
	
	# Apply axial tilt (rotation axis tilt)
	if data.has("axial_tilt"):
		mesh_instance.rotation_degrees.z = data["axial_tilt"]
	
	# Create material
	var material = StandardMaterial3D.new()
	
	# Apply color map only (no bump maps)
	if data["color_map"] != null:
		material.albedo_texture = data["color_map"]
	else:
		# Default colors if no texture
		if body_name == "Phobos" or body_name == "Deimos":
			material.albedo_color = Color(0.5, 0.45, 0.4)
		elif body_name == "Earth":
			material.albedo_color = Color(0.2, 0.4, 0.8)
	
	# Emissive for Sun
	if data.get("emissive", false):
		material.emission_enabled = true
		material.emission = Color(1.0, 0.9, 0.7)
		material.emission_energy_multiplier = 2.0
	
	material.roughness = 0.8
	material.metallic = 0.0
	
	mesh_instance.material_override = material
	
	# Position planet at orbital distance (semi-major axis)
	mesh_instance.position = Vector3(distance, 0, 0)
	
	ellipse_node.add_child(mesh_instance)
	
	# Create orbital trajectory line
	if not is_moon:
		# Only show orbit lines for planets, not moons
		create_orbit_trajectory(orbit_node, distance, data.get("eccentricity", 0.0))
	else:
		# Create smaller, dimmer orbit lines for moons
		create_moon_orbit_trajectory(orbit_node, distance, data.get("eccentricity", 0.0))
	
	# Create rings if needed
	if data.get("has_ring", false):
		var ring_tilt = data.get("axial_tilt", 0.0)
		create_ring(mesh_instance, data["ring_texture"], actual_size, ring_tilt)
	
	# Store reference with orbital parameters
	planet_nodes[body_name] = {
		"orbit": orbit_node,
		"ellipse": ellipse_node,
		"mesh": mesh_instance,
		"data": data,
		"distance": distance,
		"orbital_angle": randf() * TAU,  # Random starting position
		"rotation_angle": 0.0,  # Current rotation
		"is_moon": is_moon
	}

func create_ring(parent: Node3D, ring_texture: Texture2D, planet_size: float, axial_tilt: float):
	var ring_mesh_instance = MeshInstance3D.new()
	ring_mesh_instance.name = "Ring"
	
	# Create ring mesh using ArrayMesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Ring parameters - adjusted for better proportions
	var inner_radius = planet_size * 1.1
	var outer_radius = planet_size * 1.5
	var segments = 256  # More segments for smoother ring
	var thickness = 0.01  # Slight thickness
	
	# Generate ring geometry (top and bottom faces)
	for side in range(2):  # 0 = top, 1 = bottom
		var y_offset = thickness if side == 0 else -thickness
		var normal_dir = -1.0 if side == 0 else +1.0
		
		for i in range(segments + 1):
			var angle = (float(i) / segments) * TAU
			var cos_a = cos(angle)
			var sin_a = sin(angle)
			
			# Inner vertex
			vertices.append(Vector3(cos_a * inner_radius, y_offset, sin_a * inner_radius))
			uvs.append(Vector2(float(i) / segments, 0.0))
			normals.append(Vector3(0, normal_dir, 0))
			
			# Outer vertex
			vertices.append(Vector3(cos_a * outer_radius, y_offset, sin_a * outer_radius))
			uvs.append(Vector2(float(i) / segments, 1.0))
			normals.append(Vector3(0, normal_dir, 0))
	
	# Generate indices for both sides
	for side in range(2):
		var offset = side * (segments + 1) * 2
		for i in range(segments):
			var base = offset + i * 2
			
			if side == 0:  # Top face (counter-clockwise)
				indices.append(base)
				indices.append(base + 2)
				indices.append(base + 1)
				
				indices.append(base + 1)
				indices.append(base + 2)
				indices.append(base + 3)
			else:  # Bottom face (clockwise)
				indices.append(base)
				indices.append(base + 1)
				indices.append(base + 2)
				
				indices.append(base + 1)
				indices.append(base + 3)
				indices.append(base + 2)
	
	# Set arrays
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# Create mesh
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	ring_mesh_instance.mesh = array_mesh
	
	# Create material with proper transparency
	var ring_material = StandardMaterial3D.new()
	ring_material.albedo_texture = ring_texture
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring_material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	ring_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	ring_material.albedo_color = Color(1, 1, 1, 0.8)  # Slight transparency
	
	ring_mesh_instance.material_override = ring_material
	ring_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Apply the planet's axial tilt to the ring (rings align with planet's equator)
	ring_mesh_instance.rotation_degrees.z = axial_tilt
	
	parent.add_child(ring_mesh_instance)

func create_orbit_trajectory(parent: Node3D, distance: float, eccentricity: float):
	var immediate_mesh = ImmediateMesh.new()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = immediate_mesh
	mesh_instance.name = "OrbitTrajectory"
	
	# Create trajectory material
	var trajectory_material = StandardMaterial3D.new()
	trajectory_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trajectory_material.albedo_color = Color(0.4, 0.5, 0.6, 0.5)
	trajectory_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trajectory_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = trajectory_material
	
	# Calculate ellipse parameters
	var a = distance  # Semi-major axis
	var e = eccentricity
	
	var segments = 360
	
	# Draw the elliptical orbit path (in XZ plane, parent handles inclination)
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, trajectory_material)
	
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		# Polar equation of ellipse with focus at origin
		var r = (a * (1.0 - e * e)) / (1.0 + e * cos(angle))
		var x = r * cos(angle)
		var z = r * sin(angle)
		immediate_mesh.surface_add_vertex(Vector3(x, 0, z))
	
	immediate_mesh.surface_end()
	
	parent.add_child(mesh_instance)

func create_moon_orbit_trajectory(parent: Node3D, distance: float, eccentricity: float):
	var immediate_mesh = ImmediateMesh.new()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = immediate_mesh
	mesh_instance.name = "MoonOrbitTrajectory"
	
	# Create trajectory material - dimmer for moons
	var trajectory_material = StandardMaterial3D.new()
	trajectory_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trajectory_material.albedo_color = Color(0.5, 0.5, 0.5, 0.3)  # Dimmer
	trajectory_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trajectory_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = trajectory_material
	
	# Calculate ellipse parameters
	var a = distance  # Semi-major axis
	var e = eccentricity
	
	var segments = 180  # Fewer segments for moons
	
	# Draw the elliptical orbit path
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, trajectory_material)
	
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		var r = (a * (1.0 - e * e)) / (1.0 + e * cos(angle))
		var x = r * cos(angle)
		var z = r * sin(angle)
		immediate_mesh.surface_add_vertex(Vector3(x, 0, z))
	
	immediate_mesh.surface_end()
	
	parent.add_child(mesh_instance)

func _process(delta):
	var scaled_delta = delta * time_scale
	
	for body_name in planet_nodes:
		var node_data = planet_nodes[body_name]
		var ellipse_node = node_data["ellipse"]
		var mesh_node = node_data["mesh"]
		var data = node_data["data"]
		var distance = node_data["distance"]
		
		# Axial rotation (day/night cycle)
		if data["rotation_period"] != 0:
			var rotation_speed = (2 * PI) / (data["rotation_period"] * 3600.0)
			mesh_node.rotate_object_local(Vector3(0, 1, 0), rotation_speed * scaled_delta)
		
		# Orbital motion with eccentricity
		if data["orbital_period"] != 0:
			var orbital_speed = (2 * PI) / (data["orbital_period"] * 86400.0)
			node_data["orbital_angle"] += orbital_speed * scaled_delta
			
			# Get orbital parameters
			var eccentricity = data.get("eccentricity", 0.0)
			var angle = node_data["orbital_angle"]
			
			# Calculate position using orbital mechanics (ellipse with Sun at focus)
			var a = distance  # Semi-major axis
			var e = eccentricity
			
			# Polar equation of ellipse with focus at origin
			var r = (a * (1.0 - e * e)) / (1.0 + e * cos(angle))
			var x = r * cos(angle)
			var z = r * sin(angle)
			
			# Update position
			mesh_node.position = Vector3(x, 0, z)
