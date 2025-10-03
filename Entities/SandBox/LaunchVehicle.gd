"""
A sandboxed blueprint for LaunchVehicle that mimics the logic
without any engine-specific dependencies.
"""
class_name LaunchVehicle

#region Identity
## The display name of the launch vehicle used in telemetry and mission logs
var NAME: String = "Unnamed Vehicle"
## The rocket family this vehicle belongs to (e.g., "Falcon", "Atlas", "Ariane")
var family: String = ""
## The company or organization that manufactured this launch vehicle
var manufacturer: String = "Astro Dynamics Corp"
## Unique mission designation identifier (e.g., "DART-1", "CREW-5", "GPS-IIIF-1")
var mission_designation: String = "DART-1"
## Serial number for this specific vehicle unit for tracking and inventory
var vehicle_serial: String = "AV-001"
#endregion


#region internals
var position:Vector3
var velocity:Vector3
var accleration:Vector3
#endregion





#region Mission Timeline Parameters
## Time in seconds after T=0 when the launch sequence begins
var launch_window: float = 0.0
## Array of times in seconds when each stage separation event occurs [s]
var stage_events: Array[float] = [120.0, 480.0]
## Time in seconds from launch when payload deployment occurs [s]
var payload_deploy_time: float = 900.0
## Duration of engine startup sequence before liftoff [s]
var engine_startup_sequence: float = 3.0
## Time delay for hold-down clamps to release after ignition [s]
var hold_down_release: float = 2.0
#endregion

#region Vehicle Design Parameters
## Dry mass (empty weight) of each stage without propellant [kg]
var stage_dry_mass: Array[float] = [2200.0, 800.0]
## Mass of propellant (fuel + oxidizer) loaded in each stage [kg]
var stage_propellant_mass: Array[float] = [18500.0, 4200.0]
## Number of engines on each stage
var engine_count: Array[int] = [9, 1]
## Type of propellant combination used (e.g., "RP1_LOX", "LH2_LOX", "Hypergolic")
var propellant_type: String = "RP1_LOX"
## Mass of the payload being delivered to orbit [kg]
var payload_mass: float = 1500.0
## Mass of the protective payload fairing structure [kg]
var payload_fairing_mass: float = 450.0
#endregion

#region Propulsion Parameters
## Maximum thrust force produced by each stage at full throttle [N]
var thrust_profile: Array[float] = [7607000.0, 934000.0]
## Specific impulse (fuel efficiency) of each stage in vacuum conditions [s]
var isp_vacuum: Array[float] = [311.0, 348.0]
## Specific impulse of each stage at sea level atmospheric pressure [s]
var isp_sea_level: Array[float] = [282.0, 348.0]
## Maximum angle the engines can gimbal for thrust vectoring control [degrees]
var gimbal_range: float = 8.5
## Minimum throttle setting as fraction of max thrust for each stage (1.0 = 100%, 0.7 = 70%)
var throttle_capability: Array[float] = [0.7, 0.4]
## Whether each stage's engines can be restarted after shutdown
var engine_restart_capable: Array[bool] = [false, true]
#endregion

#region Flight Path Parameters
## Initial pitch angle at liftoff (90.0 = straight up, 0.0 = horizontal) [degrees]
var initial_pitch: float = 90.0
## Rate of pitch change during gravity turn maneuver [degrees/s]
var pitch_turn_rate: float = 0.8
## Target orbital inclination relative to equator [degrees]
var target_inclination: float = 28.5
## Compass heading for launch trajectory (90.0 = due east, 0.0 = north) [degrees]
var launch_azimuth: float = 90.0
## Condition that determines engine cutoff ("velocity", "altitude", or "time")
var cutoff_condition: String = "velocity"
## Target orbital velocity for mission success [m/s]
var target_velocity: float = 11200.0
## Target apoapsis (highest point) altitude for the orbit [m]
var target_apoapsis: float = 400000.0
#endregion

#region Payload Deployment Parameters
## Delta-v (velocity change) applied during payload separation [m/s]
var separation_delta_v: float = 2.5
## Direction vector for payload separation in local coordinates
var separation_orientation: Vector3 = Vector3.FORWARD
## Whether to apply spin stabilization to the payload after deployment
var spin_stabilization: bool = true
## Rotation rate for spin stabilization [RPM - revolutions per minute]
var spin_rate: float = 2.0
## Whether spring-loaded mechanisms are used for payload ejection
var payload_deployment_springs: bool = true
## Force applied by deployment springs during separation [N]
var spring_force: float = 150.0
#endregion

#region Telemetry & Status
## Whether telemetry data transmission is enabled
var telemetry_enabled: bool = true
## Rate of telemetry data transmission to ground stations [Hz]
var data_transmission_rate: float = 2.0
#endregion

#region State Variables
## Current mission elapsed time since T=0 [s]
var current_time: float = 0.0
## Whether the vehicle has lifted off from the launch pad
var launched: bool = false
## Whether the pre-launch ignition sequence has started
var ignition_sequence_started: bool = false
## Index of currently firing stage (-1 = none, 0 = first stage, 1 = second stage, etc.)
var active_stage: int = -1
## Whether the payload has been successfully deployed
var payload_deployed: bool = false
## Whether the payload fairing has been jettisoned
var fairing_jettisoned: bool = false
## Current velocity vector of the vehicle [m/s]
var current_velocity: Vector3 = Vector3.ZERO
## Current altitude above launch site [m]
var current_altitude: float = 0.0
## Current acceleration magnitude [m/s²]
var current_acceleration: float = 0.0
## Remaining propellant mass in each stage [kg]
var fuel_remaining: Array[float] = []
## Operational status of each engine (true = nominal, false = shutdown/failed)
var engine_status: Array[bool] = []
## Whether the guidance computer is actively controlling the vehicle
var guidance_active: bool = false
## Whether telemetry signal lock with ground stations is maintained
var telemetry_lock: bool = true

## Enumeration of all possible flight phases during a mission
enum FlightPhase {
	PRE_LAUNCH,           ## Vehicle on pad, all systems ready
	IGNITION_SEQUENCE,    ## Engines starting up
	LIFTOFF,              ## Vehicle clearing the tower
	FIRST_STAGE_BURN,     ## First stage propulsion
	STAGE_SEPARATION,     ## Staging event in progress
	SECOND_STAGE_BURN,    ## Upper stage propulsion
	COAST_PHASE,          ## Unpowered ballistic flight
	PAYLOAD_DEPLOYMENT,   ## Payload separation
	MISSION_COMPLETE      ## All objectives achieved
}
## Current phase of the flight mission
var current_phase: FlightPhase = FlightPhase.PRE_LAUNCH
#endregion

#region Initialization
## Initializes all vehicle systems and prepares for launch. Must be called before flight operations.
## Sets up fuel arrays, engine status, and prints telemetry readiness information.
func initialize():
	fuel_remaining = stage_propellant_mass.duplicate()
	engine_status.resize(engine_count.reduce(func(a,b): return a+b, 0))
	engine_status.fill(true)

	if telemetry_enabled:
		print("=== LAUNCH VEHICLE TELEMETRY INITIALIZED ===")
		print("Vehicle:", NAME, "(", vehicle_serial, ")")
		print("Mission:", mission_designation)
		print("Manufacturer:", manufacturer)
		print("Total Mass:", _calculate_total_mass(), "kg")
		print("Target ΔV:", separation_delta_v, "km/s")
#endregion

#region External Interfaces
## Schedules the launch window to begin at a specific time after T=0.
## @param time: Mission elapsed time when launch should commence [s]
func schedule_launch(time: float) -> void:
	launch_window = time
	print("Launch window set: T+", time, "s")

## Initiates the launch sequence if not already launched or in progress.
## Starts engine ignition sequence and transitions to IGNITION_SEQUENCE phase.
func initiate_launch_sequence() -> void:
	if launched or ignition_sequence_started: return
	ignition_sequence_started = true
	current_phase = FlightPhase.IGNITION_SEQUENCE
	print("=== LAUNCH SEQUENCE INITIATED ===")
	print("Engine startup sequence begins in T-", engine_startup_sequence, "s")

## Aborts the launch sequence if vehicle has not yet lifted off.
## Returns vehicle to safe PRE_LAUNCH state. Only works before liftoff.
func abort_launch() -> void:
	if not launched and ignition_sequence_started:
		ignition_sequence_started = false
		current_phase = FlightPhase.PRE_LAUNCH
		print("LAUNCH ABORTED - Vehicle safed")

## Ignites engines and commits to launch. This is the point of no return.
## Activates first stage, enables guidance, and transitions to LIFTOFF phase.
func ignite() -> void:
	if launched: return
	launched = true
	active_stage = 0
	current_phase = FlightPhase.LIFTOFF
	guidance_active = true
	print("=== IGNITION ===")
	print("All engines: NOMINAL")
	print("Thrust:", thrust_profile[0] / 1000.0, "kN")
	print(NAME, " has cleared the tower!")

## Performs stage separation and ignites the next stage if available.
## Transitions to next stage or COAST_PHASE if no more propulsive stages remain.
func separate_stage() -> void:
	if active_stage < 0 or active_stage >= stage_events.size(): return
	var separating_stage = active_stage
	print("=== STAGE ", separating_stage + 1, " SEPARATION ===")
	print("Separation confirmed at T+", current_time, "s")
	active_stage += 1
	if active_stage < thrust_profile.size():
		print("Stage ", active_stage + 1, " ignition: CONFIRMED")
	else:
		print("All propulsive stages: DEPLETED")
		current_phase = FlightPhase.COAST_PHASE

## Jettisons the payload fairing once outside the atmosphere.
## Reduces vehicle mass and exposes the payload. Can only be done once.
func jettison_fairing() -> void:
	if fairing_jettisoned: return
	fairing_jettisoned = true
	print("=== FAIRING JETTISON ===")
	print("Payload fairing separation: CONFIRMED")

## Deploys the payload and completes the primary mission objective.
## Applies separation velocity, optional spin stabilization, and transitions to MISSION_COMPLETE.
func deploy_payload() -> void:
	if payload_deployed: return
	payload_deployed = true
	current_phase = FlightPhase.PAYLOAD_DEPLOYMENT
	print("=== PAYLOAD DEPLOYMENT ===")
	print("Payload separation: CONFIRMED")
	if spin_stabilization:
		print("Spin stabilization: ACTIVE (", spin_rate, "RPM)")
	current_phase = FlightPhase.MISSION_COMPLETE

## Emergency shutdown of all engines and guidance systems.
## Use only in case of critical anomaly or abort scenario.
func emergency_shutdown() -> void:
	guidance_active = false
	print("EMERGENCY ENGINE SHUTDOWN")
#endregion

#region Flight Mechanics
## Calculates the current total mass of the vehicle including all stages, fuel, and payload.
## @return: Total vehicle mass in kilograms [kg]
func _calculate_total_mass() -> float:
	var total = payload_mass + payload_fairing_mass
	for i in range(stage_dry_mass.size()):
		total += stage_dry_mass[i] + fuel_remaining[i]
	return total

## Calculates the current thrust-to-weight ratio of the active stage.
## TWR > 1.0 means the vehicle can accelerate upward against gravity.
## @return: Thrust-to-weight ratio (dimensionless)
func _calculate_twr() -> float:
	if active_stage < 0 or active_stage >= thrust_profile.size():
		return 0.0
	var weight = _calculate_total_mass() * 9.81
	return thrust_profile[active_stage] / weight

## Updates telemetry data for the current frame. Should be called every physics step.
## Simulates altitude gain, acceleration, and velocity changes based on thrust and mass.
## @param delta: Time elapsed since last update [s]
func update_telemetry(delta: float) -> void:
	if not telemetry_enabled: return
	if launched and active_stage >= 0:
		# Simulate basic flight parameters
		current_altitude += 50.0 * delta
		current_acceleration = _calculate_twr() * 9.81 - 9.81
		current_velocity += Vector3.UP * current_acceleration * delta
#endregion

#region Utility Functions
## Returns a human-readable description of the current mission status.
## Useful for UI displays and mission control readouts.
## @return: Status message string describing current flight phase
func get_mission_status() -> String:
	match current_phase:
		FlightPhase.PRE_LAUNCH: return "Vehicle ready for launch"
		FlightPhase.IGNITION_SEQUENCE: return "Ignition sequence in progress"
		FlightPhase.LIFTOFF: return "Vehicle ascending"
		FlightPhase.FIRST_STAGE_BURN: return "First stage burn"
		FlightPhase.STAGE_SEPARATION: return "Stage separation in progress"
		FlightPhase.SECOND_STAGE_BURN: return "Upper stage burn"
		FlightPhase.COAST_PHASE: return "Coasting to deployment"
		FlightPhase.PAYLOAD_DEPLOYMENT: return "Payload deployment"
		FlightPhase.MISSION_COMPLETE: return "Primary mission complete"
		_: return "Unknown status"

## Returns a dictionary containing all current telemetry data.
## Useful for data logging, transmission to ground stations, and debugging.
## @return: Dictionary with keys: time, altitude, velocity, acceleration, mass, twr, phase, fuel_remaining, guidance_active
func get_telemetry_data() -> Dictionary:
	return {
		"time": current_time,
		"altitude": current_altitude,
		"velocity": current_velocity.length(),
		"acceleration": current_acceleration,
		"mass": _calculate_total_mass(),
		"twr": _calculate_twr(),
		"phase": FlightPhase.keys()[current_phase],
		"fuel_remaining": fuel_remaining,
		"guidance_active": guidance_active
	}
#endregion
