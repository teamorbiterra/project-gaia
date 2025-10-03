extends SceneBase
@onready var three_d_container = %threeD_container

#region reference 
var key_ref= ["designation","neo_reference_id","epoch_tdb","a_km","e",
			"i_deg","raan_deg","argp_deg","M_deg","H_mag","diameter_km","albedo","pha_flag"]
#endregion reference

#region NEOFootPrintClass
class NEOFootPrint:
	var designation: String
	var neo_reference_id
	var epoch_tdb: float
	var a_km: float
	var e: float
	var i_deg: float
	var raan_deg: float
	var argp_deg: float
	var M_deg: float
	var H_mag: float
	var diameter_km: float
	var albedo
	var pha_flag: bool
	
	# New calculated parameters
	var orbital_period: float
	var perihelion_distance: float
	var aphelion_distance: float
	var orbital_velocity: float
	var mean_motion: float  # radians per second
	
	# Gravitational constant (G) and mass of the Sun (M)
	const G = 6.67430e-11 # m^3⋅kg^−1⋅s^−2
	const M = 1.989e30     # kg (mass of the Sun)
	const AU_TO_KM = 149597870.7  # 1 AU in kilometers
	
	# Calculate orbital period (in years) using Kepler's third law
	func calculate_orbital_period():
		var a_meters = a_km * 1000  # Convert to meters
		orbital_period = 2 * PI * sqrt(pow(a_meters, 3) / (G * M))
		var orbital_period_years = orbital_period / (60 * 60 * 24 * 365.25)
		# Calculate mean motion (radians per second)
		mean_motion = 2 * PI / orbital_period
		return orbital_period_years
	
	# Calculate perihelion distance (closest approach to the Sun)
	func calculate_perihelion():
		perihelion_distance = a_km * (1 - e)
	
	# Calculate aphelion distance (farthest distance from the Sun)
	func calculate_aphelion():
		aphelion_distance = a_km * (1 + e)
	
	# Calculate orbital velocity at perihelion (in km/s)
	func calculate_orbital_velocity():
		var perihelion_distance_meters = perihelion_distance * 1000
		var velocity = sqrt(G * M / perihelion_distance_meters)
		orbital_velocity = velocity / 1000
	
	# Solve Kepler's equation using Newton-Raphson method
	func solve_kepler_equation(M: float, tolerance: float = 1e-6) -> float:
		var E = M  # Initial guess
		var delta = 1.0
		var iterations = 0
		var max_iterations = 100
		
		while abs(delta) > tolerance and iterations < max_iterations:
			delta = (E - e * sin(E) - M) / (1 - e * cos(E))
			E = E - delta
			iterations += 1
		
		return E
	
	# Calculate true anomaly from eccentric anomaly
	func eccentric_to_true_anomaly(E: float) -> float:
		var nu = 2 * atan2(sqrt(1 + e) * sin(E / 2), sqrt(1 - e) * cos(E / 2))
		return nu
	
	# Calculate position in orbital plane (2D)
	func get_orbital_plane_position(nu: float) -> Vector2:
		var r = a_km * (1 - e * e) / (1 + e * cos(nu))
		var x = r * cos(nu)
		var y = r * sin(nu)
		return Vector2(x, y)
	
	# Rotate from orbital plane to 3D space
	func orbital_to_cartesian(pos_2d: Vector2) -> Vector3:
		var x_orb = pos_2d.x
		var y_orb = pos_2d.y
		
		# Convert angles to radians
		var i_rad = deg_to_rad(i_deg)
		var raan_rad = deg_to_rad(raan_deg)
		var argp_rad = deg_to_rad(argp_deg)
		
		# Rotation matrices
		var cos_raan = cos(raan_rad)
		var sin_raan = sin(raan_rad)
		var cos_i = cos(i_rad)
		var sin_i = sin(i_rad)
		var cos_argp = cos(argp_rad)
		var sin_argp = sin(argp_rad)
		
		# Combined rotation
		var x = (cos_raan * cos_argp - sin_raan * sin_argp * cos_i) * x_orb + \
				(-cos_raan * sin_argp - sin_raan * cos_argp * cos_i) * y_orb
		
		var y = (sin_raan * cos_argp + cos_raan * sin_argp * cos_i) * x_orb + \
				(-sin_raan * sin_argp + cos_raan * cos_argp * cos_i) * y_orb
		
		var z = (sin_argp * sin_i) * x_orb + (cos_argp * sin_i) * y_orb
		
		return Vector3(x, y, z)
	
	# Main function: Get 3D position at any time
	func get_position_at_time(time_seconds: float) -> Vector3:
		# Calculate mean anomaly at time t
		var M_rad = deg_to_rad(M_deg)
		var M_t = M_rad + mean_motion * (time_seconds - epoch_tdb)
		
		# Normalize to [0, 2π]
		M_t = fmod(M_t, 2 * PI)
		if M_t < 0:
			M_t += 2 * PI
		
		# Solve Kepler's equation
		var E = solve_kepler_equation(M_t)
		
		# Get true anomaly
		var nu = eccentric_to_true_anomaly(E)
		
		# Get position in orbital plane
		var pos_2d = get_orbital_plane_position(nu)
		
		# Convert to 3D Cartesian
		var pos_3d = orbital_to_cartesian(pos_2d)
		
		return pos_3d
	
	# Function to get the calculated parameters
	func get_calculated_parameters():
		return {
			"orbital_period (years)": orbital_period / (60 * 60 * 24 * 365.25),
			"perihelion_distance (km)": perihelion_distance,
			"aphelion_distance (km)": aphelion_distance,
			"orbital_velocity (km/s)": orbital_velocity,
			"mean_motion (rad/s)": mean_motion
		}

#endregion NEOFootPrintClass

const NEODB = preload("res://Data Processing Server/Externals/neodb.json")

func _ready():
	if is_node_ready():
		if Globals.active_neo_designation != "":
			print("just get an active neo!")
			print(Globals.active_neo_designation)
		load_neo()

var prefab_path = "res://Data Processing Server/NEO Library/NEO Prefabs/"
var current_neo: Node3D
var current_neo_footprint: NEOFootPrint
var simulation_time: float = 0.0
var time_scale: float = 10*86400.0  # Seconds per frame (1 day per frame default)
var orbit_scale: float = 5.0  # Godot units radius
var max_distance_km: float = 0.0  # Will be set to aphelion distance

# Trajectory visualization
var trajectory_mesh: MeshInstance3D
var earth_sphere: MeshInstance3D
const EARTH_DISTANCE_KM = 149597870.7  # 1 AU in km (Earth's distance from Sun)

func load_neo():
	var neo_scene: PackedScene = load(prefab_path + Globals.active_neo_designation + ".tscn")
	if neo_scene.can_instantiate():
		print("neo scene can instantiate")
		current_neo = neo_scene.instantiate()
		add_child(current_neo)
	else:
		print("neo scene can not be instantiate")
	
	if is_instance_valid(current_neo):
		print("NEO loaded")
	
	# Load the data and build a footprint
	var data = NEODB.data
	for obj in data.get("objects"):
		if obj is Dictionary:
			if obj.get("designation") == Globals.active_neo_designation:
				current_neo_footprint = NEOFootPrint.new()
				for key in key_ref:
					current_neo_footprint.set(key, obj.get(key))
					current_neo.set_meta(key, obj.get(key, null))
				
				# Calculate orbital parameters
				current_neo_footprint.calculate_perihelion()
				current_neo_footprint.calculate_aphelion()
				current_neo_footprint.calculate_orbital_period()
				current_neo_footprint.calculate_orbital_velocity()
				
				# Set max distance for scaling
				max_distance_km = current_neo_footprint.aphelion_distance
				
				# Initialize simulation time to epoch
				simulation_time = current_neo_footprint.epoch_tdb
				
				break
	
	show_neo_foot_print()
	create_trajectory_visualization()
	create_earth_sphere()

func show_neo_foot_print():
	print("\n=== NEO Footprint ===")
	for key in key_ref:
		print(key, ": ", current_neo_footprint.get(key))
	
	print("\n=== Calculated Parameters ===")
	var calc_params = current_neo_footprint.get_calculated_parameters()
	for key in calc_params:
		print(key, ": ", calc_params[key])

func _process(delta):
	if current_neo_footprint and is_instance_valid(current_neo):
		# Advance simulation time
		simulation_time += delta * time_scale
		
		# Get position at current simulation time
		var pos_km = current_neo_footprint.get_position_at_time(simulation_time)
		
		# Scale to Godot units (clamp to 5 unit radius)
		var scaled_pos = scale_to_godot_units(pos_km)
		
		# Update NEO position
		current_neo.global_position = scaled_pos
		
		# Optional: Print debug info every second
		var time_elapsed = simulation_time - current_neo_footprint.epoch_tdb
		if int(time_elapsed) % int(time_scale) == 0 and Engine.get_frames_drawn() % 60 == 0:
			print("Time: ", time_elapsed / 86400.0, " days | Pos: ", scaled_pos)

# Scale real-world km coordinates to Godot 5-unit radius
func scale_to_godot_units(pos_km: Vector3) -> Vector3:
	# Scale factor: 5 Godot units = max_distance_km
	var scale_factor = orbit_scale / max_distance_km
	return pos_km * scale_factor

# Optional: Function to set time scale (for fast-forwarding)
func set_time_scale(days_per_second: float):
	time_scale = days_per_second * 86400.0  # Convert days to seconds

# Optional: Reset simulation to epoch
func reset_simulation():
	simulation_time = current_neo_footprint.epoch_tdb

# Create trajectory visualization using ImmediateMesh
func create_trajectory_visualization():
	var imesh = ImmediateMesh.new()
	trajectory_mesh = MeshInstance3D.new()
	trajectory_mesh.mesh = imesh
	add_child(trajectory_mesh)
	
	# Create material for the orbit line
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.5, 0.0, 0.8)  # Orange orbit
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trajectory_mesh.material_override = material
	
	# Calculate one complete orbit (sample points)
	var num_points = 360  # One point per degree
	var orbital_period_seconds = current_neo_footprint.orbital_period
	var time_step = orbital_period_seconds / num_points
	
	imesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for i in range(num_points + 1):  # +1 to close the loop
		var time = current_neo_footprint.epoch_tdb + (i * time_step)
		var pos_km = current_neo_footprint.get_position_at_time(time)
		var scaled_pos = scale_to_godot_units(pos_km)
		
		imesh.surface_add_vertex(scaled_pos)
	
	imesh.surface_end()
	
	print("Trajectory visualization created with ", num_points, " points")

# Create Earth sphere at correct orbital position
func create_earth_sphere():
	earth_sphere = MeshInstance3D.new()
	add_child(earth_sphere)
	
	# Create sphere mesh
	var sphere = SphereMesh.new()
	sphere.radius = 0.1  # Small sphere to represent Earth
	sphere.height = 0.2
	earth_sphere.mesh = sphere
	
	# Create blue material for Earth
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 1.0)  # Blue Earth
	material.metallic = 0.3
	material.roughness = 0.7
	earth_sphere.material_override = material
	
	# Calculate Earth's position (assuming circular orbit at 1 AU)
	# Earth is at approximately (1 AU, 0, 0) in heliocentric coordinates
	var earth_pos_km = Vector3(EARTH_DISTANCE_KM, 0, 0)
	var earth_scaled_pos = scale_to_godot_units(earth_pos_km)
	earth_sphere.global_position = earth_scaled_pos
	
	print("Earth placed at: ", earth_scaled_pos, " (Godot units)")
	print("Earth distance: ", EARTH_DISTANCE_KM, " km (1 AU)")
