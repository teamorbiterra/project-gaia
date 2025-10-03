extends RichTextLabel
class_name LaunchVehicleDocumentation

# This script generates comprehensive documentation for the LaunchVehicle class
# Attach this to a RichTextLabel node to display the documentation

func _ready():
	setup_documentation()

func setup_documentation():
	bbcode_enabled = true
	
	# Godot 4.5 scrolling fix
	fit_content = false  # This prevents scrolling in 4.5
	scroll_active = true
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selection_enabled=true
	# Ensure the RichTextLabel has a fixed size
	# Either set it in the editor or programmatically:
	# custom_minimum_size = Vector2(800, 600)  # Uncomment if needed
	
	var doc_text = generate_documentation()
	text = doc_text
	
	# Force scroll to top after content is set
	

func generate_documentation() -> String:
	return """
[center][font_size=24][color=gold]🚀 LAUNCH VEHICLE SYSTEM DOCUMENTATION[/color][/font_size][/center]
[color=silver]═══════════════════════════════════════════════════════════════════[/color]

[font_size=18][color=cyan]MISSION OVERVIEW[/color][/font_size]
The Launch Vehicle system is designed for [color=orange]asteroid deflection missions[/color], capable of delivering precision payloads to intercept trajectories. This documentation covers all configurable parameters and their operational impact.

[color=silver]───────────────────────────────────────────────────────────────────[/color]

[font_size=16][color=lightgreen]📋 IDENTITY PARAMETERS[/color][/font_size]

[color=yellow]• NAME[/color] - Vehicle designation (e.g., "Falcon Heavy", "Atlas V")
  └─ [color=gray]Automatically sets the node name for scene organization[/color]

[color=yellow]• family[/color] - Rocket family classification (e.g., "Falcon", "Atlas", "Ariane")
  └─ [color=gray]Used for grouping similar vehicle configurations[/color]

[color=yellow]• manufacturer[/color] - Aerospace company responsible for the vehicle
  └─ [color=gray]Default: "Astro Dynamics Corp" - appears in telemetry logs[/color]

[color=yellow]• mission_designation[/color] - Mission identifier (e.g., "DART-1", "OSIRIS-2")
  └─ [color=gray]Critical for mission tracking and reporting[/color]

[color=yellow]• vehicle_serial[/color] - Unique vehicle identifier (e.g., "AV-001")
  └─ [color=gray]Essential for vehicle history and maintenance tracking[/color]

[color=silver]───────────────────────────────────────────────────────────────────[/color]

[font_size=16][color=lightgreen]⏰ MISSION TIMELINE PARAMETERS[/color][/font_size]

[color=yellow]• launch_window[/color] - Launch delay in seconds after T=0
  └─ [color=gray]Allows for weather holds, range conflicts, or orbital mechanics[/color]
  └─ [color=gray]Set via schedule_launch(time) function[/color]

[color=yellow]• stage_events[/color] - Array of stage separation times (seconds)
  └─ [color=gray]Example: [120.0, 480.0] = Stage 1 sep at T+2min, Stage 2 at T+8min[/color]
  └─ [color=gray]Timing critical for proper trajectory insertion[/color]

[color=yellow]• payload_deploy_time[/color] - Payload release time (seconds)
  └─ [color=gray]Must occur after final stage burnout for clean separation[/color]

[color=yellow]• engine_startup_sequence[/color] - Pre-ignition preparation time
  └─ [color=gray]Typical: 3-6 seconds for engine spin-up and system checks[/color]

[color=yellow]• hold_down_release[/color] - Clamp release delay after ignition
  └─ [color=gray]Allows engines to reach stable thrust before liftoff[/color]

[color=silver]───────────────────────────────────────────────────────────────────[/color]

[font_size=16][color=lightgreen]🔧 VEHICLE DESIGN PARAMETERS[/color][/font_size]

[color=yellow]• stage_dry_mass[/color] - Empty mass of each stage (kg)
  └─ [color=gray]Includes structure, engines, avionics, recovery systems[/color]
  └─ [color=gray]Lower values = better performance, higher cost/complexity[/color]

[color=yellow]• stage_propellant_mass[/color] - Fuel capacity per stage (kg)
  └─ [color=gray]Directly affects burn duration and total ΔV capability[/color]
  └─ [color=gray]Must be balanced with structural limits[/color]

[color=yellow]• engine_count[/color] - Number of engines per stage
  └─ [color=gray]More engines = higher thrust, redundancy, but complexity[/color]
  └─ [color=gray]Example: [9, 1] = Falcon 9 configuration[/color]

[color=yellow]• propellant_type[/color] - Chemical propulsion system
  └─ [color=orange]RP1_LOX[/color]: Kerosene/Oxygen - High density, moderate performance
  └─ [color=orange]LH2_LOX[/color]: Hydrogen/Oxygen - High performance, low density
  └─ [color=orange]Solid[/color]: Pre-mixed propellant - Simple, non-throttleable
  └─ [color=orange]Hypergolic[/color]: Self-igniting - Reliable, toxic
  └─ [color=orange]Methalox[/color]: Methane/Oxygen - Future propulsion, Mars-producible

[color=yellow]• payload_mass[/color] - Mass of the deflection payload (kg)
  └─ [color=gray]Typically 500-2000kg for asteroid missions[/color]

[color=yellow]• payload_fairing_mass[/color] - Protective shroud mass (kg)
  └─ [color=gray]Jettisoned automatically above 100km altitude[/color]

[color=silver]───────────────────────────────────────────────────────────────────[/color]

[font_size=16][color=lightgreen]🔥 PROPULSION PARAMETERS[/color][/font_size]

[color=yellow]• thrust_profile[/color] - Maximum thrust per stage (Newtons)
  └─ [color=gray]Determines acceleration and climb rate[/color]
  └─ [color=gray]Example: 7,607,000 N = Falcon 9 first stage thrust[/color]

[color=yellow]• isp_vacuum[/color] - Specific impulse in space (seconds)
  └─ [color=gray]Higher = more efficient fuel usage in vacuum[/color]
  └─ [color=gray]RP-1: ~311s, LH2: ~450s, Solid: ~290s[/color]

[color=yellow]• isp_sea_level[/color] - Specific impulse at launch (seconds)
  └─ [color=gray]Always lower than vacuum due to atmospheric pressure[/color]

[color=yellow]• gimbal_range[/color] - Engine steering capability (degrees)
  └─ [color=gray]Essential for guidance and control during ascent[/color]
  └─ [color=gray]Typical range: 5-15 degrees[/color]

[color=yellow]• throttle_capability[/color] - Minimum throttle setting (fraction)
  └─ [color=gray]Lower values = better flight control, landing capability[/color]

[color=yellow]• engine_restart_capable[/color] - Multi-burn capability per stage
  └─ [color=gray]Critical for complex orbital insertion sequences[/color]

[color=silver]───────────────────────────────────────────────────────────────────[/color]

[font_size=16][color=lightgreen]🛰️ FLIGHT PATH PARAMETERS[/color][/font_size]

[color=yellow]• initial_pitch[/color] - Launch angle (90° = straight up)
  └─ [color=gray]Slight eastward lean can improve efficiency[/color]

[color=yellow]• pitch_turn_rate[/color] - Gravity turn rate (degrees/second)
  └─ [color=gray]Gradual turn reduces gravity losses and stress[/color]

[color=yellow]• target_inclination[/color] - Orbital plane angle (degrees)
  └─ [color=gray]28.5° = Cape Canaveral equatorial launch[/color]
  └─ [color=gray]Higher inclinations cost more fuel[/color]

[color=yellow]• launch_azimuth[/color] - Compass heading at launch
  └─ [color=gray]90° = due east (utilizes Earth's rotation)[/color]

[color=yellow]• cutoff_condition[/color] - Stage shutdown trigger
  └─ [color=orange]"velocity"[/color]: Stop at target speed
  └─ [color=orange]"time"[/color]: Fixed burn duration
  └─ [color=orange]"apoapsis"[/color]: Stop at target altitude

[color=yellow]• target_velocity[/color] - Desired final speed (m/s)
  └─ [color=gray]11,200 m/s = escape velocity for asteroid intercept[/color]

[color=yellow]• target_apoapsis[/color] - Target highest altitude (meters)
  └─ [color=gray]400km typical for staging to escape trajectory[/color]

[color=silver]───────────────────────────────────────────────────────────────────[/color]

[font_size=16][color=lightgreen]📦 PAYLOAD DEPLOYMENT PARAMETERS[/color][/font_size]

[color=yellow]• separation_delta_v[/color] - Imparted velocity (km/s)
  └─ [color=gray]2.5 km/s typical for asteroid intercept missions[/color]
  └─ [color=gray]Higher values = faster transit, less precision[/color]

[color=yellow]• separation_orientation[/color] - Deployment direction vector
  └─ [color=gray]Usually Vector3.FORWARD for prograde separation[/color]

[color=yellow]• spin_stabilization[/color] - Payload spin for stability
  └─ [color=gray]Prevents tumbling during long cruise phases[/color]

[color=yellow]• spin_rate[/color] - Rotation speed (RPM)
  └─ [color=gray]1-5 RPM typical - too fast causes structural stress[/color]

[color=yellow]• spring_force[/color] - Mechanical separation force (Newtons)
  └─ [color=gray]Ensures clean separation without contact[/color]

[color=silver]───────────────────────────────────────────────────────────────────[/color]

[font_size=16][color=lightgreen]📡 TELEMETRY & MONITORING[/color][/font_size]

[color=yellow]• telemetry_enabled[/color] - Data transmission toggle
  └─ [color=gray]Provides real-time flight status and diagnostics[/color]

[color=yellow]• data_transmission_rate[/color] - Bandwidth (Mbps)
  └─ [color=gray]Higher rates = more detailed monitoring capability[/color]

[color=silver]───────────────────────────────────────────────────────────────────[/color]

[font_size=16][color=lightgreen]🎮 OPERATIONAL CONTROL FUNCTIONS[/color][/font_size]

[color=orange]schedule_launch(time)[/color] - Set launch window delay
[color=orange]initiate_launch_sequence()[/color] - Begin countdown (user control)
[color=orange]abort_launch()[/color] - Emergency shutdown before liftoff
[color=orange]separate_stage()[/color] - Manual stage separation trigger
[color=orange]deploy_payload()[/color] - Manual payload release
[color=orange]emergency_shutdown()[/color] - Immediate engine cutoff
[color=orange]get_mission_status()[/color] - Current flight phase string
[color=orange]get_telemetry_data()[/color] - Real-time flight data dictionary

[color=silver]───────────────────────────────────────────────────────────────────[/color]

[font_size=16][color=lightgreen]⚠️ FLIGHT PHASES[/color][/font_size]

[color=orange]1. PRE_LAUNCH[/color] - Vehicle ready, awaiting user command
[color=orange]2. IGNITION_SEQUENCE[/color] - Engines starting, system checks
[color=orange]3. LIFTOFF[/color] - Vehicle ascending under power
[color=orange]4. FIRST_STAGE_BURN[/color] - Primary boost phase
[color=orange]5. STAGE_SEPARATION[/color] - Staging events in progress
[color=orange]6. SECOND_STAGE_BURN[/color] - Upper stage propulsion
[color=orange]7. COAST_PHASE[/color] - Unpowered flight to deployment
[color=orange]8. PAYLOAD_DEPLOYMENT[/color] - Mission payload release
[color=orange]9. MISSION_COMPLETE[/color] - Primary objectives achieved

[color=silver]───────────────────────────────────────────────────────────────────[/color]

[font_size=16][color=lightgreen]💡 PERFORMANCE TIPS[/color][/font_size]

[color=yellow]• Mass Ratio[/color]: Keep stage dry mass low relative to propellant
[color=yellow]• Staging[/color]: More stages = higher performance, more complexity  
[color=yellow]• TWR[/color]: Target 1.2-1.8 at liftoff for optimal ascent
[color=yellow]• Propellant[/color]: RP-1 for first stage, LH2 for upper stages
[color=yellow]• Timing[/color]: Precise staging critical for mission success
[color=yellow]• Redundancy[/color]: Multiple engines provide failure tolerance

[color=silver]═══════════════════════════════════════════════════════════════════[/color]
[center][color=gold]End of Launch Vehicle Documentation[/color][/center]
"""

func update_documentation_for_vehicle(vehicle: LaunchVehicle):
	"""Updates the documentation with live data from a specific vehicle instance"""
	if not vehicle:
		return
	
	var live_data = """

[color=silver]───────────────────────────────────────────────────────────────────[/color]
[font_size=16][color=lightgreen]📊 LIVE VEHICLE DATA[/color][/font_size]

[color=cyan]Vehicle:[/color] %s (%s)
[color=cyan]Mission:[/color] %s
[color=cyan]Current Phase:[/color] %s
[color=cyan]Total Mass:[/color] %.1f kg
[color=cyan]Current TWR:[/color] %.2f
[color=cyan]Mission Time:[/color] T+%.1fs
""" % [
		vehicle.NAME,
		vehicle.vehicle_serial, 
		vehicle.mission_designation,
		vehicle.get_mission_status(),
		vehicle._calculate_total_mass() if vehicle.has_method("_calculate_total_mass") else 0.0,
		vehicle._calculate_twr() if vehicle.has_method("_calculate_twr") else 0.0,
		vehicle.current_time
	]
	
	text += live_data

func _force_scroll_reset():
	"""Force scroll to reset - needed in Godot 4.5"""
	scroll_to_line(0)
	get_v_scroll_bar().value = 0

func _input(event):
	"""Handle manual scrolling if automatic scrolling still doesn't work"""
	if not has_focus():
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_to_line(max(0, get_visible_line_count() - 5))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_to_line(min(get_line_count(), get_visible_line_count() + 5))
			get_viewport().set_input_as_handled()
