extends WorldEnvironment

var noise: FastNoiseLite
var cover: NoiseTexture2D
var sky_material: ProceduralSkyMaterial

# Store original offset for reference
var original_offset: Vector3

# Animation parameters - only for smooth movement
var time: float = 0.0
var wind_direction: Vector2 = Vector2(1.0, 0.3)  # Wind direction
var wind_base_speed: float = 0.1  # Much faster base speed
var wind_variation_speed: float = 0.03  # More noticeable variation

# Smooth wind variation parameters
var wind_speed_variation_frequency: float = 0.05  # Faster variation
var wind_direction_variation_frequency: float = 0.03  # More noticeable direction changes
var wind_direction_variation_amount: float = 0.3

func _ready():
	var env := environment
	if not env:
		push_warning("No environment set!")
		return
	
	var sky := env.sky
	if not sky:
		push_warning("No sky set in environment!")
		return
	
	sky_material = sky.sky_material
	if sky_material is ProceduralSkyMaterial:
		cover = sky_material.sky_cover
		if cover is NoiseTexture2D and cover.noise:
			noise = cover.noise
			original_offset = noise.offset
			print("Smooth offset-only sky animation initialized")
		else:
			push_warning("Sky cover is not a NoiseTexture2D with noise")
	else:
		push_warning("Sky material is not ProceduralSkyMaterial")

func _process(delta):
	if not noise or not cover:
		return
	
	time += delta
	
	# Create smooth, organic wind movement using multiple sine waves
	
	# 1. Base wind movement with smooth speed variation
	var speed_variation = sin(time * wind_speed_variation_frequency) * wind_variation_speed
	var current_wind_speed = wind_base_speed + speed_variation
	
	# 2. Smooth wind direction changes
	var direction_variation_x = sin(time * wind_direction_variation_frequency) * wind_direction_variation_amount
	var direction_variation_y = cos(time * wind_direction_variation_frequency * 1.3 + 1.0) * wind_direction_variation_amount * 0.5
	
	var current_wind_direction = wind_direction + Vector2(direction_variation_x, direction_variation_y)
	current_wind_direction = current_wind_direction.normalized()
	
	# 3. Apply smooth movement to noise offset
	var movement = current_wind_direction * current_wind_speed * delta
	noise.offset.x += movement.x
	noise.offset.y += movement.y
	
	# 4. Add more noticeable turbulence for organic movement
	var turbulence_x = sin(time * 0.2 + noise.offset.x * 0.5) * 0.02
	var turbulence_y = cos(time * 0.15 + noise.offset.y * 0.5) * 0.015
	
	noise.offset.x += turbulence_x
	noise.offset.y += turbulence_y

# Simple wind control functions
func set_wind_speed(speed: float):
	"""Set base wind speed"""
	wind_base_speed = clamp(speed, 0.001, 0.1)

func set_wind_direction_vector(direction: Vector2):
	"""Set wind direction as a Vector2"""
	wind_direction = direction.normalized()

func set_wind_turbulence(amount: float):
	"""Set how much the wind varies (0.0 = steady, 1.0 = very turbulent)"""
	wind_variation_speed = lerp(0.001, 0.02, clamp(amount, 0.0, 1.0))
	wind_direction_variation_amount = lerp(0.05, 0.5, clamp(amount, 0.0, 1.0))
	wind_speed_variation_frequency = lerp(0.01, 0.08, clamp(amount, 0.0, 1.0))

# Weather presets
func set_calm_weather():
	"""Gentle, barely moving clouds"""
	set_wind_speed(0.008)
	set_wind_turbulence(0.1)
	set_wind_direction_vector(Vector2(1.0, 0.2))

func set_breezy_weather():
	"""Moderate wind with some variation"""
	set_wind_speed(0.025)
	set_wind_turbulence(0.4)
	set_wind_direction_vector(Vector2(1.0, 0.3))

func set_windy_weather():
	"""Strong, variable winds"""
	set_wind_speed(0.055)
	set_wind_turbulence(0.8)
	set_wind_direction_vector(Vector2(1.2, 0.5))

func transition_wind_speed(target_speed: float, duration: float = 10.0):
	"""Smoothly transition to new wind speed"""
	var tween = create_tween()
	tween.tween_method(set_wind_speed, wind_base_speed, target_speed, duration)

func transition_to_weather(weather_type: String, duration: float = 15.0):
	"""Smooth transition to weather preset"""
	var target_speed: float
	var target_turbulence: float
	var target_direction: Vector2
	
	match weather_type:
		"calm":
			target_speed = 0.008
			target_turbulence = 0.1
			target_direction = Vector2(1.0, 0.2)
		"breezy":
			target_speed = 0.025
			target_turbulence = 0.4
			target_direction = Vector2(1.0, 0.3)
		"windy":
			target_speed = 0.055
			target_turbulence = 0.8
			target_direction = Vector2(1.2, 0.5)
		_:
			return
	
	var tween = create_tween()
	tween.parallel().tween_method(set_wind_speed, wind_base_speed, target_speed, duration)
	tween.parallel().tween_method(set_wind_turbulence, wind_variation_speed / 0.02, target_turbulence, duration)
	# Direction changes are handled automatically through the wind system
