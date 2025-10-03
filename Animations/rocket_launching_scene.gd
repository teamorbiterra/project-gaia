extends Node3D
@onready var animation_player = $PhoneixLaunchVehicle/AnimationPlayer

@onready var launch_button = $Control/launch_button
@onready var gpu_particles_3d = $PhoneixLaunchVehicle/RocketBody/GPUParticles3D


var launched= false

func _ready():
	launch_button.pressed.connect(
		func():
		gpu_particles_3d.emitting=true	
		await get_tree().create_timer(1.0).timeout
		animation_player.play("ClipperAction")
		await animation_player.animation_finished
		await get_tree().create_timer(1.0).timeout
		launched=true
	)

@onready var rocket_body = $PhoneixLaunchVehicle/RocketBody

func _process(delta):
	if launched:
		rocket_body.global_position.y+=5.0*delta
