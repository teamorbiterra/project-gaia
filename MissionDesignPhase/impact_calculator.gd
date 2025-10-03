extends Node
class_name ImpactCalculator

@onready var impact_modeler = $".."

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

# Torino Scale thresholds (collision probability × kinetic energy)
const TORINO_THRESHOLDS = [0, 1e-8, 1e-6, 1e-4, 1e-2, 0.01]

#endregion Constants

var current_assessment: ImpactAssessment
var neo_footprint: Object  # Reference to NEOFootPrint from parent

func _ready():
	print("\n=== Impact Calculator Initialized ===")

# Main function to calculate all impact parameters
func calculate_impact_assessment(footprint: Object) -> ImpactAssessment:
	neo_footprint = footprint
	current_assessment = ImpactAssessment.new()
	
	print("\n=== Calculating Impact Assessment ===")
	
	# Step 1: Calculate NEO mass
	calculate_neo_mass()
	
	# Step 2: Find closest approach to Earth
	calculate_closest_approach()
	
	# Step 3: Calculate MOID (Minimum Orbit Intersection Distance)
	calculate_moid()
	
	# Step 4: Estimate collision probability
	estimate_collision_probability()
	
	# Step 5: Calculate Torino Scale
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
	
	# Step 9: Determine if ocean impact and calculate tsunami
	determine_impact_type()
	if current_assessment.is_ocean_impact:
		calculate_tsunami_parameters()
	
	# Step 10: Estimate casualties (requires impact location)
	estimate_casualties()
	
	print_assessment_summary()
	
	return current_assessment

#region Mass and Energy Calculations

func calculate_neo_mass():
	# Volume of sphere: V = (4/3) × π × r³
	var radius_m = (neo_footprint.diameter_km * 1000.0) / 2.0
	var volume_m3 = (4.0 / 3.0) * PI * pow(radius_m, 3)
	
	# Mass = Volume × Density
	current_assessment.neo_mass_kg = volume_m3 * TYPICAL_ASTEROID_DENSITY
	
	print("NEO Mass: ", current_assessment.neo_mass_kg, " kg (", 
		  current_assessment.neo_mass_kg / 1e9, " billion kg)")

func calculate_impact_velocity():
	# Impact velocity = sqrt(v_neo² + v_escape²)
	# where v_escape = sqrt(2 × G × M_earth / R_earth)
	
	var v_escape_m_s = sqrt(2.0 * G * EARTH_MASS_KG / (EARTH_RADIUS_KM * 1000.0))
	var v_neo_m_s = neo_footprint.orbital_velocity * 1000.0  # Convert km/s to m/s
	
	var v_impact_m_s = sqrt(pow(v_neo_m_s, 2) + pow(v_escape_m_s, 2))
	current_assessment.impact_velocity_km_s = v_impact_m_s / 1000.0
	
	print("Impact Velocity: ", current_assessment.impact_velocity_km_s, " km/s")

func calculate_kinetic_energy():
	# KE = 0.5 × m × v²
	var velocity_m_s = current_assessment.impact_velocity_km_s * 1000.0
	current_assessment.kinetic_energy_joules = 0.5 * current_assessment.neo_mass_kg * pow(velocity_m_s, 2)
	
	# Convert to megatons TNT
	current_assessment.tnt_equivalent_megatons = current_assessment.kinetic_energy_joules / TNT_JOULES_PER_MEGATON
	
	print("Kinetic Energy: ", current_assessment.kinetic_energy_joules, " J")
	print("TNT Equivalent: ", current_assessment.tnt_equivalent_megatons, " megatons")

#endregion Mass and Energy Calculations

#region Orbital Calculations

func calculate_closest_approach():
	# Sample the orbit over one period to find closest approach to Earth
	var orbital_period_seconds = neo_footprint.orbital_period
	var num_samples = 1000
	var time_step = orbital_period_seconds / num_samples
	
	var min_distance = INF
	var closest_time = 0.0
	
	var earth_position = Vector3(impact_modeler.EARTH_DISTANCE_KM, 0, 0)
	
	for i in range(num_samples):
		var time = neo_footprint.epoch_tdb + (i * time_step)
		var neo_pos = neo_footprint.get_position_at_time(time)
		var distance = neo_pos.distance_to(earth_position)
		
		if distance < min_distance:
			min_distance = distance
			closest_time = time
	
	current_assessment.closest_approach_distance_km = min_distance
	current_assessment.closest_approach_date = closest_time
	
	print("Closest Approach Distance: ", min_distance, " km")
	print("Closest Approach Date: ", closest_time / 86400.0, " days from epoch")

func calculate_moid():
	# Simplified MOID calculation
	# MOID is the minimum distance between two orbital paths
	# For simplicity, we'll use the perihelion distance comparison
	
	var neo_perihelion = neo_footprint.perihelion_distance
	var neo_aphelion = neo_footprint.aphelion_distance
	var earth_orbit_radius = impact_modeler.EARTH_DISTANCE_KM
	
	# Check if orbits intersect
	if neo_perihelion < earth_orbit_radius and neo_aphelion > earth_orbit_radius:
		# Orbits cross Earth's orbital distance
		current_assessment.moid_km = abs(current_assessment.closest_approach_distance_km - EARTH_RADIUS_KM)
	else:
		current_assessment.moid_km = min(
			abs(neo_perihelion - earth_orbit_radius),
			abs(neo_aphelion - earth_orbit_radius)
		)
	
	print("MOID (Minimum Orbit Intersection Distance): ", current_assessment.moid_km, " km")

func estimate_collision_probability():
	# Simplified collision probability based on MOID and orbital parameters
	# Real calculation requires uncertainty ellipsoids
	
	var cross_section = PI * pow(EARTH_RADIUS_KM, 2)
	var orbital_uncertainty = 1000.0  # Assumed 1000 km uncertainty
	
	if current_assessment.moid_km < EARTH_RADIUS_KM + orbital_uncertainty:
		# Potentially hazardous
		var proximity_factor = 1.0 - (current_assessment.moid_km / (EARTH_RADIUS_KM + orbital_uncertainty))
		current_assessment.collision_probability = proximity_factor * 0.001  # Scale to reasonable probability
	else:
		current_assessment.collision_probability = 0.0
	
	# Clamp to [0, 1]
	current_assessment.collision_probability = clamp(current_assessment.collision_probability, 0.0, 1.0)
	
	print("Collision Probability: ", current_assessment.collision_probability * 100, "%")

func calculate_torino_scale():
	# Torino Scale: 0-10 based on collision probability and impact energy
	var energy_factor = current_assessment.tnt_equivalent_megatons
	var prob = current_assessment.collision_probability
	
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
	
	print("Torino Scale: ", current_assessment.torino_scale, " / 10")

#endregion Orbital Calculations

#region Impact Effects Calculations

func calculate_crater_parameters():
	# Empirical crater scaling laws
	# D = C × (E/ρ)^0.22 where D is diameter, E is energy, ρ is target density
	
	var target_density = 2500.0  # kg/m³ (rock)
	var energy_megatons = current_assessment.tnt_equivalent_megatons
	
	# Convert to joules for calculation
	var energy_joules = energy_megatons * TNT_JOULES_PER_MEGATON
	
	# Crater diameter (simplified formula)
	current_assessment.crater_diameter_km = 0.0013 * pow(energy_megatons, 0.3)
	
	# Crater depth (typically 1/10 to 1/5 of diameter)
	current_assessment.crater_depth_km = current_assessment.crater_diameter_km * 0.15
	
	print("Crater Diameter: ", current_assessment.crater_diameter_km, " km")
	print("Crater Depth: ", current_assessment.crater_depth_km, " km")

func calculate_air_blast_effects():
	# Air blast radius based on overpressure
	# Total destruction: 20 psi overpressure
	# Severe damage: 5 psi
	# Moderate damage: 1 psi
	
	var energy_kt = current_assessment.tnt_equivalent_megatons * 1000  # Convert to kilotons
	
	# Scaling from nuclear weapon effects
	current_assessment.total_destruction_radius_km = 0.3 * pow(energy_kt, 0.33)
	current_assessment.severe_damage_radius_km = 0.6 * pow(energy_kt, 0.33)
	current_assessment.moderate_damage_radius_km = 1.2 * pow(energy_kt, 0.33)
	current_assessment.air_blast_radius_km = current_assessment.moderate_damage_radius_km
	
	print("Air Blast Radius (moderate damage): ", current_assessment.air_blast_radius_km, " km")

func calculate_thermal_effects():
	# Thermal radiation radius (3rd degree burns)
	var energy_kt = current_assessment.tnt_equivalent_megatons * 1000
	
	current_assessment.thermal_radiation_radius_km = 0.8 * pow(energy_kt, 0.41)
	current_assessment.fireball_radius_km = 0.1 * pow(energy_kt, 0.4)
	
	print("Thermal Radiation Radius: ", current_assessment.thermal_radiation_radius_km, " km")
	print("Fireball Radius: ", current_assessment.fireball_radius_km, " km")

func calculate_seismic_effects():
	# Seismic magnitude from impact energy
	# M = 0.67 × log10(E) - 5.87 (where E is in joules)
	
	var energy_joules = current_assessment.kinetic_energy_joules
	current_assessment.seismic_magnitude = 0.67 * log(energy_joules) / log(10) - 5.87
	
	print("Seismic Magnitude: ", current_assessment.seismic_magnitude, " (Richter scale)")

#endregion Impact Effects Calculations

#region Tsunami Calculations

func determine_impact_type():
	# 71% chance of ocean impact
	current_assessment.is_ocean_impact = randf() < OCEAN_COVERAGE
	
	# For simulation, you could also check impact location coordinates
	print("Impact Type: ", "Ocean" if current_assessment.is_ocean_impact else "Land")

func calculate_tsunami_parameters():
	# Simplified tsunami calculation for deep water impacts
	
	var energy_megatons = current_assessment.tnt_equivalent_megatons
	var diameter_m = neo_footprint.diameter_km * 1000.0
	
	# Initial wave amplitude (meters) - empirical formula
	var wave_amplitude = 0.1 * pow(energy_megatons, 0.5)
	current_assessment.tsunami_wave_height_m = wave_amplitude * 10  # Amplification near coast
	
	# Inundation distance (how far inland)
	# Depends on coastal slope, but rough estimate
	current_assessment.tsunami_inundation_distance_km = wave_amplitude * 0.5
	
	# Affected coastline (circular propagation)
	var max_travel_distance_km = 10000.0  # Tsunamis can travel across oceans
	current_assessment.affected_coastline_km = 2 * PI * max_travel_distance_km * 0.3  # 30% of circumference
	
	print("\n=== Tsunami Parameters ===")
	print("Wave Height at Coast: ", current_assessment.tsunami_wave_height_m, " meters")
	print("Inundation Distance: ", current_assessment.tsunami_inundation_distance_km, " km inland")
	print("Affected Coastline: ", current_assessment.affected_coastline_km, " km")

#endregion Tsunami Calculations

#region Casualty Estimation

func estimate_casualties():
	# Simplified casualty estimation
	# Real calculation would require population density maps
	
	# Random impact location (for simulation)
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
		# Land impact casualties
		current_assessment.population_in_blast_radius = int(blast_area * avg_population_density)
	
	# Casualty rates by zone
	var total_destruction_area = PI * pow(current_assessment.total_destruction_radius_km, 2)
	var severe_damage_area = PI * pow(current_assessment.severe_damage_radius_km, 2) - total_destruction_area
	
	var immediate_casualties = int(total_destruction_area * avg_population_density * 0.9)  # 90% fatality
	immediate_casualties += int(severe_damage_area * avg_population_density * 0.5)  # 50% fatality
	
	current_assessment.estimated_immediate_casualties = immediate_casualties
	current_assessment.estimated_total_casualties = int(immediate_casualties * 1.5)  # Include delayed casualties
	
	# Affected countries (simplified)
	current_assessment.affected_countries = ["Country A", "Country B"]  # Placeholder
	
	print("\n=== Casualty Estimates ===")
	print("Impact Location: ", current_assessment.impact_location)
	print("Population in Affected Area: ", current_assessment.population_in_blast_radius)
	print("Immediate Casualties: ", current_assessment.estimated_immediate_casualties)
	print("Total Casualties (est.): ", current_assessment.estimated_total_casualties)

#endregion Casualty Estimation

#region Reporting

func print_assessment_summary():
	print("\n" + "=".repeat(60))
	print("IMPACT ASSESSMENT SUMMARY")
	print("=".repeat(60))
	
	print("\nORBITAL RISK:")
	print("  MOID: ", current_assessment.moid_km, " km")
	print("  Closest Approach: ", current_assessment.closest_approach_distance_km, " km")
	print("  Collision Probability: ", current_assessment.collision_probability * 100, "%")
	print("  Torino Scale: ", current_assessment.torino_scale, " / 10")
	
	print("\nIMPACT ENERGY:")
	print("  NEO Mass: ", current_assessment.neo_mass_kg / 1e12, " trillion kg")
	print("  Impact Velocity: ", current_assessment.impact_velocity_km_s, " km/s")
	print("  TNT Equivalent: ", current_assessment.tnt_equivalent_megatons, " megatons")
	
	print("\nIMPACT EFFECTS:")
	print("  Crater Diameter: ", current_assessment.crater_diameter_km, " km")
	print("  Seismic Magnitude: ", current_assessment.seismic_magnitude)
	print("  Air Blast Radius: ", current_assessment.air_blast_radius_km, " km")
	print("  Thermal Radius: ", current_assessment.thermal_radiation_radius_km, " km")
	
	if current_assessment.is_ocean_impact:
		print("\nTSUNAMI EFFECTS:")
		print("  Wave Height: ", current_assessment.tsunami_wave_height_m, " meters")
		print("  Inundation Distance: ", current_assessment.tsunami_inundation_distance_km, " km")
	
	print("\nCAUSUALTY ESTIMATES:")
	print("  Immediate Casualties: ", current_assessment.estimated_immediate_casualties)
	print("  Total Casualties: ", current_assessment.estimated_total_casualties)
	
	print("=".repeat(60) + "\n")

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

# Public function to get current assessment
func get_assessment() -> ImpactAssessment:
	return current_assessment

# Save assessment to file
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
