extends Node
class_name MissionControllerProgram

## Called during the mission design phase.
## Allocate resources, configure payloads, set mission parameters.
func on_design():
	pass

## Called during pre-launch checks.
## Verify launch vehicle readiness, sensor calibration, and system status.
func on_prelaunch():
	pass

## Called to initiate the launch sequence.
## Handles engine ignition, clamp detachment, and initial ascent.
func on_launch():
	pass

## Called during the ascent phase.
## Control staging events, throttle, trajectory, and vehicle stability.
func on_ascent():
	pass

## Called once the vehicle has reached orbit.
## Handle payload deployment and prepare for mission operations.
func on_orbit():
	pass

## Called during mission operations.
## Manage payload activities, sensor data collection, and experiments.
func on_mission_ops():
	pass

## Called if reentry is part of the mission.
## Handle deorbit burns, heatshield deployment, and landing procedures.
func on_reentry():
	pass

## Called at the end of the mission.
## Perform final cleanup, log mission summary, and reset systems.
func on_shutdown():
	pass
	

static func get_custom_name():
	return "MissionControllerProgram"
