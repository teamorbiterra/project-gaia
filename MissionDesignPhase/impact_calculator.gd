extends Node
class_name ImpactCalculator

# === PARENT NODE REFERENCE ===
@onready var impact_modeler = $".."

# === SIGNAL DECLARATION ===
# Emitted when assessment calculation is complete
# Connected by parent node (ImpactModeler) to trigger visualization refresh
signal assessment_complete(assessment_data)

#region Impact Data Structure
class ImpactAssessment:
	# Collision Risk Parameters
	var moid_km: float = 0.0  # Minimum Orbit Intersection Distance
	var closest_approach_date: float = 0.0
	var closest_approach_distance_km: float = 0.0
	var collision_probability: float = 0.0
	var torino_scale: int = 0  # 0-10 scale
	
	# Impact Energy Parameters
	var neo_mass_kg: float = 0.0
	var impact_velocity_km_s: float = 0.0
	var kinetic_energy_joules: float = 0.0
	var tnt_equivalent_megatons: float = 0.0
	
	# Impact Effects (if collision occurs)
	var crater_diameter_km: float = 0.0
	var crater_depth_km: float = 0.0
	var seismic_magnitude: float = 0.0
	var air_blast_radius_km: float = 0.0
	var thermal_radiation_radius_km: float = 0.0
	var fireball_radius_km: float = 0.0
	
	# Tsunami Parameters (ocean impact)
	var is_ocean_impact: bool = false
	var tsunami_wave_height_m: float = 0.0
	var tsunami_inundation_distance_km: float = 0.0
	var affected_coastline_km: float = 0.0
	
	# Casualty Estimates
	var impact_location: Vector2 = Vector2.ZERO  # lat, lon
	var population_in_blast_radius: int = 0
	var estimated_immediate_casualties: int = 0
	var estimated_total_casualties: int = 0
	var affected_countries: Array = []
	
	# Damage Zones
	var total_destruction_radius_km: float = 0.0
	var severe_damage_radius_km: float = 0.0
	var moderate_damage_radius_km: float = 0.0

#endregion Impact Data Structure

#region Constants
const EARTH_RADIUS_KM = 6371.0
const EARTH_MASS_KG = 5.972e24
const G = 6.67430e-11  # Gravitational constant
const TYPICAL_ASTEROID_DENSITY = 2500.0  # kg/m³ (rocky asteroid)
const OCEAN_COVERAGE = 0.71  # 71% of Earth is ocean
const TNT_JOULES_PER_MEGATON = 4.184e15  # Joules in 1 megaton TNT
#endregion Constants

# === STATE VARIABLES ===
var current_assessment: ImpactAssessment
var neo_footprint: Object  # Reference to NEOFootPrint from parent

# === INITIALIZATION ===
func _ready():
	print("\n=== Impact Calculator Initialized ===")

# === MAIN CALCULATION FUNCTION ===
# Calculates all impact parameters and emits signal when complete
func calculate_impact_assessment(footprint: Object) -> ImpactAssessment:
	print("\n" + "=".repeat(60))
	print("STARTING IMPACT ASSESSMENT CALCULATION")
	print("=".repeat(60))
	
	# Store reference to NEO data
	neo_footprint = footprint
	current_assessment = ImpactAssessment.new()
	
	# Verify footprint data is valid
	if not neo_footprint:
		push_error("ImpactCalculator: Received null footprint!")
		return null
	
	# === CALCULATION PIPELINE ===
	# Each step builds on previous calculations
	
	# Step 1: Calculate NEO mass from diameter
	calculate_neo_mass()
	
	# Step 2: Find closest approach to Earth
	calculate_closest_approach()
	
	# Step 3: Calculate MOID (Minimum Orbit Intersection Distance)
	calculate_moid()
	
	# Step 4: Estimate collision probability
	estimate_collision_probability()
	
	# Step 5: Calculate Torino Scale (hazard rating)
	calculate_torino_scale()
	
	# Step 6: Calculate impact velocity
	calculate_impact_velocity()
	
	# Step 7: Calculate kinetic energy
	calculate_kinetic_energy()
	
	# Step 8: Calculate impact effects
	calculate_crater_parameters()
	calculate_air_blast_effects()
	calculate_thermal_effects()
	calculate_seismic_effects()
	
	# Step 9: Determine impact type and calculate tsunami if ocean impact
	determine_impact_type()
	if current_assessment.is_ocean_impact:
		calculate_tsunami_parameters()
	
	# Step 10: Estimate casualties
	estimate_casualties()
	
	# Print summary to console
	print_assessment_summary()
	
	print("\n=== Assessment calculation complete ===")
	
	# CRITICAL: Emit signal to notify parent that calculation is done
	# This triggers the canvas to refresh with new data
	assessment_complete.emit(current_assessment)
	print("ImpactCalculator: Emitted assessment_complete signal")
	
	return current_assessment

#region Mass and Energy Calculations

# Calculate NEO mass from diameter using assumed density
func calculate_neo_mass():
	# Volume of sphere: V = (4/3) × π × r³
	var radius_m = (neo_footprint.diameter_km * 1000.0) / 2.0
	var volume_m3 = (4.0 / 3.0) * PI * pow(radius_m, 3)
	
	# Mass = Volume × Density
	current_assessment.neo_mass_kg = volume_m3 * TYPICAL_ASTEROID_DENSITY
	
	print("NEO Mass: ", current_assessment.neo_mass_kg, " kg (", 
		  snapped(current_assessment.neo_mass_kg / 1e9, 0.01), " billion kg)")

# Calculate impact velocity combining orbital velocity and Earth's escape velocity
func calculate_impact_velocity():
	# Impact velocity = sqrt(v_neo² + v_escape²)
	# where v_escape = sqrt(2 × G × M_earth / R_earth)
	
	var v_escape_m_s = sqrt(2.0 * G * EARTH_MASS_KG / (EARTH_RADIUS_KM * 1000.0))
	var v_neo_m_s = neo_footprint.orbital_velocity * 1000.0  # Convert km/s to m/s
	
	var v_impact_m_s = sqrt(pow(v_neo_m_s, 2) + pow(v_escape_m_s, 2))
	current_assessment.impact_velocity_km_s = v_impact_m_s / 1000.0
	
	print("Impact Velocity: ", snapped(current_assessment.impact_velocity_km_s, 0.1), " km/s")

# Calculate kinetic energy and TNT equivalent
func calculate_kinetic_energy():
	# KE = 0.5 × m × v²
	var velocity_m_s = current_assessment.impact_velocity_km_s * 1000.0
	current_assessment.kinetic_energy_joules = 0.5 * current_assessment.neo_mass_kg * pow(velocity_m_s, 2)
	
	# Convert to megatons TNT for easier comprehension
	current_assessment.tnt_equivalent_megatons = current_assessment.kinetic_energy_joules / TNT_JOULES_PER_MEGATON
	
	print("Kinetic Energy: ", current_assessment.kinetic_energy_joules, " J")
	print("TNT Equivalent: ", snapped(current_assessment.tnt_equivalent_megatons, 0.01), " megatons")

#endregion Mass and Energy Calculations

#region Orbital Calculations

# Sample orbit to find closest approach to Earth
func calculate_closest_approach():
	var orbital_period_seconds = neo_footprint.orbital_period
	var num_samples = 1000  # Sample points across one complete orbit
	var time_step = orbital_period_seconds / num_samples
	
	var min_distance = INF
	var closest_time = 0.0
	
	# Earth's position (simplified: circular orbit at 1 AU)
	var earth_position = Vector3(impact_modeler.EARTH_DISTANCE_KM, 0, 0)
	
	# Sample NEO position throughout its orbit
	for i in range(num_samples):
		var time = neo_footprint.epoch_tdb + (i * time_step)
		var neo_pos = neo_footprint.get_position_at_time(time)
		var distance = neo_pos.distance_to(earth_position)
		
		if distance < min_distance:
			min_distance = distance
			closest_time = time
	
	current_assessment.closest_approach_distance_km = min_distance
	current_assessment.closest_approach_date = closest_time
	
	print("Closest Approach Distance: ", snapped(min_distance, 0.1), " km")
	print("Closest Approach Date: ", snapped(closest_time / 86400.0, 0.1), " days from epoch")

# Calculate Minimum Orbit Intersection Distance
func calculate_moid():
	# Simplified MOID calculation
	# MOID is the minimum distance between two orbital paths
	
	var neo_perihelion = neo_footprint.perihelion_distance
	var neo_aphelion = neo_footprint.aphelion_distance
	var earth_orbit_radius = impact_modeler.EARTH_DISTANCE_KM
	
	# Check if orbits intersect Earth's orbital distance
	if neo_perihelion < earth_orbit_radius and neo_aphelion > earth_orbit_radius:
		# Orbits cross Earth's orbital distance - potentially hazardous
		current_assessment.moid_km = abs(current_assessment.closest_approach_distance_km - EARTH_RADIUS_KM)
	else:
		# Orbits don't cross - find minimum distance between orbit ranges
		current_assessment.moid_km = min(
			abs(neo_perihelion - earth_orbit_radius),
			abs(neo_aphelion - earth_orbit_radius)
		)
	
	print("MOID (Minimum Orbit Intersection Distance): ", snapped(current_assessment.moid_km, 0.1), " km")

# Estimate collision probability based on MOID and uncertainties
func estimate_collision_probability():
	# Simplified collision probability
	# Real calculations require detailed uncertainty ellipsoids
	
	var cross_section = PI * pow(EARTH_RADIUS_KM, 2)
	var orbital_uncertainty = 1000.0  # Assumed 1000 km uncertainty in trajectory
	
	if current_assessment.moid_km < EARTH_RADIUS_KM + orbital_uncertainty:
		# Potentially hazardous - within uncertainty range
		var proximity_factor = 1.0 - (current_assessment.moid_km / (EARTH_RADIUS_KM + orbital_uncertainty))
		current_assessment.collision_probability = proximity_factor * 0.001  # Scale to reasonable probability
	else:
		# Outside uncertainty range - no collision risk
		current_assessment.collision_probability = 0.0
	
	# Ensure probability is between 0 and 1
	current_assessment.collision_probability = clamp(current_assessment.collision_probability, 0.0, 1.0)
	
	print("Collision Probability: ", snapped(current_assessment.collision_probability * 100, 0.001), "%")

# Calculate Torino Scale (0-10 hazard rating)
func calculate_torino_scale():
	# Torino Scale combines collision probability and impact energy
	var energy_factor = current_assessment.tnt_equivalent_megatons
	var prob = current_assessment.collision_probability
	
	# Scale determination based on NASA Torino Scale criteria
	if prob == 0 or energy_factor < 1:
		current_assessment.torino_scale = 0  # No hazard
	elif prob < 1e-8:
		current_assessment.torino_scale = 0
	elif prob < 1e-6 and energy_factor < 100:
		current_assessment.torino_scale = 1  # Normal
	elif prob < 1e-4 and energy_factor < 1000:
		current_assessment.torino_scale = 2  # Merits attention
	elif prob < 0.01 and energy_factor < 10000:
		current_assessment.torino_scale = 3  # Deserving attention
	elif prob < 0.01:
		current_assessment.torino_scale = 4  # Close encounter
	elif prob < 0.1 and energy_factor < 10000:
		current_assessment.torino_scale = 5  # Threatening
	elif prob < 0.1:
		current_assessment.torino_scale = 6
	elif prob < 1.0 and energy_factor < 100000:
		current_assessment.torino_scale = 7  # Very threatening
	elif prob < 1.0:
		current_assessment.torino_scale = 8
	elif energy_factor < 1000000:
		current_assessment.torino_scale = 9  # Certain collision - regional
	else:
		current_assessment.torino_scale = 10  # Certain collision - global catastrophe
	
	print("Torino Scale: ", current_assessment.torino_scale, " / 10 (", get_risk_level_description(), ")")

#endregion Orbital Calculations

#region Impact Effects Calculations

# Calculate crater dimensions using scaling laws
func calculate_crater_parameters():
	# Empirical crater scaling laws
	# Based on impact energy and target material properties
	
	var energy_megatons = current_assessment.tnt_equivalent_megatons
	
	# Crater diameter (simplified Schmidt-Holsapple formula)
	# D ≈ C × E^0.3 where C is a constant
	current_assessment.crater_diameter_km = 0.0013 * pow(energy_megatons, 0.3)
	
	# Crater depth (typically 1/10 to 1/5 of diameter for complex craters)
	current_assessment.crater_depth_km = current_assessment.crater_diameter_km * 0.15
	
	print("Crater Diameter: ", snapped(current_assessment.crater_diameter_km, 0.01), " km")
	print("Crater Depth: ", snapped(current_assessment.crater_depth_km, 0.01), " km")

# Calculate air blast damage zones
func calculate_air_blast_effects():
	# Air blast radius based on overpressure levels
	# Total destruction: 20 psi overpressure
	# Severe damage: 5 psi
	# Moderate damage: 1 psi
	
	var energy_kt = current_assessment.tnt_equivalent_megatons * 1000  # Convert to kilotons
	
	# Scaling from nuclear weapon effects research
	current_assessment.total_destruction_radius_km = 0.3 * pow(energy_kt, 0.33)
	current_assessment.severe_damage_radius_km = 0.6 * pow(energy_kt, 0.33)
	current_assessment.moderate_damage_radius_km = 1.2 * pow(energy_kt, 0.33)
	current_assessment.air_blast_radius_km = current_assessment.moderate_damage_radius_km
	
	print("Air Blast Radius (moderate damage): ", snapped(current_assessment.air_blast_radius_km, 0.1), " km")
	print("Total Destruction Radius: ", snapped(current_assessment.total_destruction_radius_km, 0.1), " km")
	print("Severe Damage Radius: ", snapped(current_assessment.severe_damage_radius_km, 0.1), " km")

# Calculate thermal radiation effects
func calculate_thermal_effects():
	# Thermal radiation radius (3rd degree burns threshold)
	var energy_kt = current_assessment.tnt_equivalent_megatons * 1000
	
	# Fireball and thermal radiation scaling
	current_assessment.thermal_radiation_radius_km = 0.8 * pow(energy_kt, 0.41)
	current_assessment.fireball_radius_km = 0.1 * pow(energy_kt, 0.4)
	
	print("Thermal Radiation Radius: ", snapped(current_assessment.thermal_radiation_radius_km, 0.1), " km")
	print("Fireball Radius: ", snapped(current_assessment.fireball_radius_km, 0.1), " km")

# Calculate seismic effects
func calculate_seismic_effects():
	# Seismic magnitude from impact energy
	# Formula: M = 0.67 × log10(E) - 5.87 (where E is in joules)
	
	var energy_joules = current_assessment.kinetic_energy_joules
	
	# Prevent log of zero or negative
	if energy_joules > 0:
		current_assessment.seismic_magnitude = 0.67 * log(energy_joules) / log(10) - 5.87
	else:
		current_assessment.seismic_magnitude = 0.0
	
	print("Seismic Magnitude: ", snapped(current_assessment.seismic_magnitude, 0.1), " (Richter scale)")

#endregion Impact Effects Calculations

#region Tsunami Calculations

# Determine if impact occurs in ocean or on land
func determine_impact_type():
	# 71% of Earth's surface is ocean
	current_assessment.is_ocean_impact = randf() < OCEAN_COVERAGE
	
	print("Impact Type: ", "Ocean" if current_assessment.is_ocean_impact else "Land")

# Calculate tsunami parameters for ocean impacts
func calculate_tsunami_parameters():
	# Simplified tsunami calculation for deep water impacts
	
	var energy_megatons = current_assessment.tnt_equivalent_megatons
	var diameter_m = neo_footprint.diameter_km * 1000.0
	
	# Initial wave amplitude (meters) - empirical formula
	var wave_amplitude = 0.1 * pow(energy_megatons, 0.5)
	
	# Wave amplification near coast (typically 10x)
	current_assessment.tsunami_wave_height_m = wave_amplitude * 10
	
	# Inundation distance (how far inland)
	# Depends on coastal slope and wave height
	current_assessment.tsunami_inundation_distance_km = wave_amplitude * 0.5
	
	# Affected coastline (circular propagation from impact point)
	var max_travel_distance_km = 10000.0  # Tsunamis can travel across oceans
	current_assessment.affected_coastline_km = 2 * PI * max_travel_distance_km * 0.3  # 30% of circumference affected
	
	print("\n=== Tsunami Parameters ===")
	print("Wave Height at Coast: ", snapped(current_assessment.tsunami_wave_height_m, 0.1), " meters")
	print("Inundation Distance: ", snapped(current_assessment.tsunami_inundation_distance_km, 0.1), " km inland")
	print("Affected Coastline: ", snapped(current_assessment.affected_coastline_km, 0.1), " km")

#endregion Tsunami Calculations

#region Casualty Estimation

# Estimate human casualties based on affected areas
func estimate_casualties():
	# Simplified casualty estimation
	# Real calculations require detailed population density maps
	
	# Generate random impact location for simulation
	current_assessment.impact_location = Vector2(
		randf_range(-90, 90),  # Latitude
		randf_range(-180, 180)  # Longitude
	)
	
	# Assume average population density
	var avg_population_density = 50  # people per km²
	
	# Calculate affected area
	var blast_area = PI * pow(current_assessment.air_blast_radius_km, 2)
	
	if current_assessment.is_ocean_impact:
		# Coastal casualties from tsunami
		var coastal_population_density = 200  # Higher density near coasts
		var affected_coastal_area = current_assessment.affected_coastline_km * current_assessment.tsunami_inundation_distance_km
		current_assessment.population_in_blast_radius = int(affected_coastal_area * coastal_population_density)
	else:
		# Land impact casualties from blast
		current_assessment.population_in_blast_radius = int(blast_area * avg_population_density)
	
	# Casualty rates by damage zone
	var total_destruction_area = PI * pow(current_assessment.total_destruction_radius_km, 2)
	var severe_damage_area = PI * pow(current_assessment.severe_damage_radius_km, 2) - total_destruction_area
	
	# Fatality rates: 90% in total destruction zone, 50% in severe damage zone
	var immediate_casualties = int(total_destruction_area * avg_population_density * 0.9)
	immediate_casualties += int(severe_damage_area * avg_population_density * 0.5)
	
	current_assessment.estimated_immediate_casualties = immediate_casualties
	
	# Include delayed casualties (injuries, infrastructure collapse, etc.)
	current_assessment.estimated_total_casualties = int(immediate_casualties * 1.5)
	
	# Affected countries (placeholder - would require geospatial analysis)
	current_assessment.affected_countries = ["Multiple regions"]
	
	print("\n=== Casualty Estimates ===")
	print("Impact Location: Lat ", snapped(current_assessment.impact_location.x, 0.1), 
		  ", Lon ", snapped(current_assessment.impact_location.y, 0.1))
	print("Population in Affected Area: ", current_assessment.population_in_blast_radius)
	print("Immediate Casualties: ", current_assessment.estimated_immediate_casualties)
	print("Total Casualties (est.): ", current_assessment.estimated_total_casualties)

#endregion Casualty Estimation

#region Reporting

# Print comprehensive assessment summary to console
func print_assessment_summary():
	print("\n" + "=".repeat(60))
	print("IMPACT ASSESSMENT SUMMARY")
	print("=".repeat(60))
	
	print("\nORBITAL RISK:")
	print("  MOID: ", snapped(current_assessment.moid_km, 0.1), " km")
	print("  Closest Approach: ", snapped(current_assessment.closest_approach_distance_km, 0.1), " km")
	print("  Collision Probability: ", snapped(current_assessment.collision_probability * 100, 0.001), "%")
	print("  Torino Scale: ", current_assessment.torino_scale, " / 10 (", get_risk_level_description(), ")")
	
	print("\nIMPACT ENERGY:")
	print("  NEO Mass: ", snapped(current_assessment.neo_mass_kg / 1e12, 0.01), " trillion kg")
	print("  Impact Velocity: ", snapped(current_assessment.impact_velocity_km_s, 0.1), " km/s")
	print("  TNT Equivalent: ", snapped(current_assessment.tnt_equivalent_megatons, 0.01), " megatons")
	
	print("\nIMPACT EFFECTS:")
	print("  Crater Diameter: ", snapped(current_assessment.crater_diameter_km, 0.01), " km")
	print("  Seismic Magnitude: ", snapped(current_assessment.seismic_magnitude, 0.1))
	print("  Air Blast Radius: ", snapped(current_assessment.air_blast_radius_km, 0.1), " km")
	print("  Thermal Radius: ", snapped(current_assessment.thermal_radiation_radius_km, 0.1), " km")
	
	if current_assessment.is_ocean_impact:
		print("\nTSUNAMI EFFECTS:")
		print("  Wave Height: ", snapped(current_assessment.tsunami_wave_height_m, 0.1), " meters")
		print("  Inundation Distance: ", snapped(current_assessment.tsunami_inundation_distance_km, 0.1), " km")
	
	print("\nCAUSUALTY ESTIMATES:")
	print("  Immediate Casualties: ", current_assessment.estimated_immediate_casualties)
	print("  Total Casualties: ", current_assessment.estimated_total_casualties)
	
	print("=".repeat(60) + "\n")

# Get text description of Torino Scale level
func get_risk_level_description() -> String:
	match current_assessment.torino_scale:
		0: return "No Hazard"
		1: return "Normal"
		2: return "Merits Attention"
		3: return "Deserving Attention"
		4: return "Close Encounter"
		5: return "Threatening"
		6: return "Threatening"
		7: return "Very Threatening"
		8: return "Certain Collision - Local"
		9: return "Certain Collision - Regional"
		10: return "Certain Collision - Global Catastrophe"
		_: return "Unknown"

#endregion Reporting

# === PUBLIC API ===

# Get current assessment (called by parent or other nodes)
func get_assessment() -> ImpactAssessment:
	return current_assessment

# Save assessment to JSON file
func save_assessment_to_file(filepath: String):
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file:
		var data = {
			"neo_designation": neo_footprint.designation,
			"moid_km": current_assessment.moid_km,
			"collision_probability": current_assessment.collision_probability,
			"torino_scale": current_assessment.torino_scale,
			"tnt_megatons": current_assessment.tnt_equivalent_megatons,
			"crater_diameter_km": current_assessment.crater_diameter_km,
			"casualties_estimated": current_assessment.estimated_total_casualties,
			"is_ocean_impact": current_assessment.is_ocean_impact
		}
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("Assessment saved to: ", filepath)
	else:
		push_error("Failed to save assessment to: ", filepath)
