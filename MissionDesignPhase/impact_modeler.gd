extends SceneBase
class_name ImpactModeler

# === CHILD NODE REFERENCES ===
# These nodes must have unique names (%) set in the editor
@onready var impact_calculator = %Impact_Calculator
@onready var canvas = %drawing_canvas
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

# === CONSTANTS ===
const NEODB = preload("res://Data Processing Server/Externals/neodb.json")

# === NEO PREFAB AND VISUALIZATION ===
var prefab_path = "res://Data Processing Server/NEO Library/NEO Prefabs/"
var current_neo: Node3D
var current_neo_footprint: NEOFootPrint

# === ORBITAL SIMULATION ===
var simulation_time: float = 0.0
var time_scale: float = 86400.0  # Seconds per frame (1 day per frame default)
var orbit_scale: float = 5.0  # Godot units radius
var max_distance_km: float = 0.0  # Will be set to aphelion distance

# === TRAJECTORY VISUALIZATION ===
var trajectory_mesh: MeshInstance3D
var earth_sphere: MeshInstance3D
const EARTH_DISTANCE_KM = 149597870.7  # 1 AU in km (Earth's distance from Sun)
const EARTH_DIAMETER_KM = 12742.0  # Earth's diameter in km

# === INITIALIZATION ===
func _ready():
	# Verify child nodes are properly referenced
	if not impact_calculator:
		push_error("ImpactModeler: Impact_Calculator node not found! Make sure it has unique name (%) enabled.")
		return
	
	if not canvas:
		push_error("ImpactModeler: drawing_canvas node not found! Make sure it has unique name (%) enabled.")
		return
	
	# Connect to impact calculator's completion signal
	# This ensures we only refresh the canvas after calculations are done
	if impact_calculator.has_signal("assessment_complete"):
		impact_calculator.assessment_complete.connect(_on_assessment_complete)
		print("ImpactModeler: Connected to assessment_complete signal")
	else:
		push_error("ImpactModeler: assessment_complete signal not found in ImpactCalculator!")
	
	# Load NEO data if available
	if is_node_ready():
		if Globals.active_neo_designation != "":
			print("ImpactModeler: Loading active NEO: ", Globals.active_neo_designation)
			load_neo()
		else:
			print("ImpactModeler: No active NEO designation set in Globals")

# === NEO LOADING ===
func load_neo():
	print("\n=== Loading NEO ===")
	
	# Step 1: Instantiate the NEO 3D model
	var neo_scene: PackedScene = load(prefab_path + Globals.active_neo_designation + ".tscn")
	if neo_scene and neo_scene.can_instantiate():
		print("ImpactModeler: NEO scene loaded successfully")
		current_neo = neo_scene.instantiate()
		add_child(current_neo)
	else:
		push_error("ImpactModeler: Failed to load NEO scene: ", prefab_path + Globals.active_neo_designation + ".tscn")
		return
	
	if not is_instance_valid(current_neo):
		push_error("ImpactModeler: NEO instance is invalid")
		return
	
	print("ImpactModeler: NEO 3D model instantiated")
	
	# Step 2: Load NEO data from database and create footprint
	var data = NEODB.data
	var neo_found = false
	
	for obj in data.get("objects"):
		if obj is Dictionary:
			if obj.get("designation") == Globals.active_neo_designation:
				neo_found = true
				print("ImpactModeler: Found NEO data in database")
				
				# Create footprint and populate with database values
				current_neo_footprint = NEOFootPrint.new()
				for key in key_ref:
					var value = obj.get(key)
					current_neo_footprint.set(key, value)
					current_neo.set_meta(key, value)
				
				# Calculate derived orbital parameters
				current_neo_footprint.calculate_perihelion()
				current_neo_footprint.calculate_aphelion()
				current_neo_footprint.calculate_orbital_period()
				current_neo_footprint.calculate_orbital_velocity()
				
				# Set max distance for proper scaling
				max_distance_km = current_neo_footprint.aphelion_distance
				
				# Initialize simulation time to epoch
				simulation_time = current_neo_footprint.epoch_tdb
				
				break
	
	if not neo_found:
		push_error("ImpactModeler: NEO designation not found in database: ", Globals.active_neo_designation)
		return
	
	# Step 3: Display footprint information
	show_neo_foot_print()
	
	# Step 4: Create visual elements (trajectory and Earth)
	create_trajectory_visualization()
	create_earth_sphere()
	
	# Step 5: Start impact calculation (will trigger signal when complete)
	print("ImpactModeler: Starting impact assessment calculation...")
	impact_calculator.calculate_impact_assessment(current_neo_footprint)
	
	# Note: Canvas refresh will happen automatically via signal when calculation completes

# === SIGNAL HANDLER ===
# Called when impact calculator finishes its assessment
func _on_assessment_complete(assessment):
	print("\n=== Impact Assessment Complete ===")
	print("ImpactModeler: Received assessment completion signal")
	
	# Verify assessment is valid
	if not assessment:
		push_error("ImpactModeler: Received null assessment!")
		return
	
	print("ImpactModeler: Assessment valid, requesting canvas refresh...")
	
	# Trigger canvas to redraw with new data
	if canvas and canvas.has_method("refresh_visualization"):
		canvas.refresh_visualization()
	else:
		push_error("ImpactModeler: Canvas or refresh_visualization method not available!")

# === DEBUG OUTPUT ===
func show_neo_foot_print():
	print("\n=== NEO Footprint ===")
	for key in key_ref:
		print("  ", key, ": ", current_neo_footprint.get(key))
	
	print("\n=== Calculated Parameters ===")
	var calc_params = current_neo_footprint.get_calculated_parameters()
	for key in calc_params:
		print("  ", key, ": ", calc_params[key])

# === ORBITAL SIMULATION ===
func _process(delta):
	# Only update if we have valid NEO data
	if not current_neo_footprint or not is_instance_valid(current_neo):
		return
	
	# Advance simulation time
	simulation_time += delta * time_scale
	
	# Get position at current simulation time
	var pos_km = current_neo_footprint.get_position_at_time(simulation_time)
	
	# Scale to Godot units (normalized to orbit_scale radius)
	var scaled_pos = scale_to_godot_units(pos_km)
	
	# Update NEO position in 3D space
	current_neo.global_position = scaled_pos
	
	# Debug output (every second of real time)
	var time_elapsed = simulation_time - current_neo_footprint.epoch_tdb
	if int(time_elapsed) % int(time_scale) == 0 and Engine.get_frames_drawn() % 60 == 0:
		print("Simulation - Days: ", snapped(time_elapsed / 86400.0, 0.1), " | Position: ", scaled_pos)

# === COORDINATE SCALING ===
# Converts real-world km coordinates to Godot units
# Maps the aphelion distance to orbit_scale (default 5 units)
func scale_to_godot_units(pos_km: Vector3) -> Vector3:
	var scale_factor = orbit_scale / max_distance_km
	return pos_km * scale_factor

# === TIME CONTROL ===
# Set simulation speed (days per second of real time)
func set_time_scale(days_per_second: float):
	time_scale = days_per_second * 86400.0  # Convert days to seconds
	print("ImpactModeler: Time scale set to ", days_per_second, " days/second")

# Reset simulation to epoch time
func reset_simulation():
	if current_neo_footprint:
		simulation_time = current_neo_footprint.epoch_tdb
		print("ImpactModeler: Simulation reset to epoch")

# === TRAJECTORY VISUALIZATION ===
# Creates a visual representation of the complete orbital path
func create_trajectory_visualization():
	if not current_neo_footprint:
		push_error("ImpactModeler: Cannot create trajectory - no footprint data")
		return
	
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
	
	# Calculate one complete orbit by sampling points
	var num_points = 360  # One point per degree
	var orbital_period_seconds = current_neo_footprint.orbital_period
	var time_step = orbital_period_seconds / num_points
	
	# Build the line strip
	imesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for i in range(num_points + 1):  # +1 to close the loop
		var time = current_neo_footprint.epoch_tdb + (i * time_step)
		var pos_km = current_neo_footprint.get_position_at_time(time)
		var scaled_pos = scale_to_godot_units(pos_km)
		
		imesh.surface_add_vertex(scaled_pos)
	
	imesh.surface_end()
	
	print("ImpactModeler: Trajectory visualization created with ", num_points, " points")

# === EARTH VISUALIZATION ===
# Creates a sphere representing Earth at 1 AU from the Sun
func create_earth_sphere():
	earth_sphere = MeshInstance3D.new()
	add_child(earth_sphere)
	
	# Calculate Earth's visual size using the same remapping as NEOs
	# This ensures consistent scale across all objects
	var clamped_diameter = clamp(EARTH_DIAMETER_KM, 0.1, 35.0)
	var earth_mesh_size = remap(clamped_diameter, 0.1, 35.0, 0.5, 1.5)
	
	# Create sphere mesh
	var sphere = SphereMesh.new()
	sphere.radius = earth_mesh_size / 2.0  # radius is half of diameter
	sphere.height = earth_mesh_size  # height is the full diameter
	earth_sphere.mesh = sphere
	
	# Create blue material for Earth
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 1.0)  # Blue Earth
	material.metallic = 0.3
	material.roughness = 0.7
	earth_sphere.material_override = material
	
	# Position Earth at 1 AU (assuming circular orbit for simplicity)
	var earth_pos_km = Vector3(EARTH_DISTANCE_KM, 0, 0)
	var earth_scaled_pos = scale_to_godot_units(earth_pos_km)
	earth_sphere.global_position = earth_scaled_pos
	
	print("ImpactModeler: Earth sphere created")
	print("  Position: ", earth_scaled_pos, " (Godot units)")
	print("  Distance: ", EARTH_DISTANCE_KM, " km (1 AU)")
	print("  Visual size: ", earth_mesh_size, " Godot units")
