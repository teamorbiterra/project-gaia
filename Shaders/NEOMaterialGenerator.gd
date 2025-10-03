extends Node
class_name NEOMaterialGenerator

# === SHADER AND MATERIAL REFERENCES ===
const NEO_SHADER_1: Shader = preload("uid://dknnycxd527h4") # Shader version 1
const NEO_SHADER_2: Shader = preload("uid://dyninbvddqa1t") # Shader version 2
const NEO_MATERIAL: ShaderMaterial = preload("uid://k6spcxxjo2h") # Base ShaderMaterial

enum MaterialVersions { V1, V2 }

@export var material_version: MaterialVersions = MaterialVersions.V1:
	set(value):
		material_version = value
		apply_shader_version()
@export var material: ShaderMaterial

# === SHADER PARAMETERS (class variables) ===
# Texture parameters
@export var noise_texture: Texture2D:
	set(value):
		noise_texture = value
		set_uniform("noise", value)

@export var normal_map_texture: Texture2D:
	set(value):
		normal_map_texture = value
		set_uniform("normal_map", value)

# Numeric parameters
@export_range(1.0,5.0,0.1) var sphere_radius: float = 1.0: 
	set(value): 
		sphere_radius = value
		set_uniform("sphere_radius", value)
		print(sphere_radius)
		
@export_range(0.0,5.0,0.1) var amplitude: float = 0.3: 
	set(value): 
		amplitude = value
		set_uniform("amplitude", value)

@export var uv_scale: Vector2 = Vector2(1, 1): 
	set(value): 
		uv_scale = value
		set_uniform("uv_scale", value)

@export var mix_color: Color = Color(1, 1, 1): 
	set(value): 
		mix_color = value
		set_uniform("mix_color", value)

@export_range(0.0,1.0,0.01) var mix_ratio: float = 0.5: 
	set(value): 
		mix_ratio = value
		set_uniform("mix_ratio", value)

@export var axis_scale: Vector3 = Vector3(1, 1, 1): 
	set(value): 
		axis_scale = value
		set_uniform("axis_scale", value)

# Note: shader v1 uses "roughtness_value", v2 uses "roughness_value"
@export var roughness_value: float = 0.0: 
	set(value): 
		roughness_value = value
		set_uniform("roughness_value", value)
		set_uniform("roughtness_value", value) # Handle typo in shader v1

@export var world_center: Vector3 = Vector3(0, 0, 0): 
	set(value): 
		world_center = value
		set_uniform("world_center", value)

@export var seam_fix_method: int = 1: 
	set(value): 
		seam_fix_method = value
		set_uniform("seam_fix_method", value)

# === Extra parameters for Shader V2 ===
@export var max_distance: float = 20.0: 
	set(value): 
		max_distance = value
		set_uniform("max_distance", value)

@export var min_amplitude_ratio: float = 0.1: 
	set(value): 
		min_amplitude_ratio = value
		set_uniform("min_amplitude_ratio", value)

@export var parallax_scale: float = 0.02: 
	set(value): 
		parallax_scale = value
		set_uniform("parallax_scale", value)

@export var parallax_steps: int = 8: 
	set(value): 
		parallax_steps = value
		set_uniform("parallax_steps", value)

func _ready():
	material = NEO_MATERIAL.duplicate()
	apply_shader_version()

func apply_shader_version():
	if not material:
		return
		
	match material_version:
		MaterialVersions.V1:
			material.shader = NEO_SHADER_1
		MaterialVersions.V2:
			material.shader = NEO_SHADER_2
	
	# Push all current values into shader
	sync_uniforms()

func sync_uniforms():
	set_uniform("noise", noise_texture)
	set_uniform("normal_map", normal_map_texture)
	set_uniform("sphere_radius", sphere_radius)
	set_uniform("amplitude", amplitude)
	set_uniform("uv_scale", uv_scale)
	set_uniform("mix_color", mix_color)
	set_uniform("mix_ratio", mix_ratio)
	set_uniform("axis_scale", axis_scale)
	set_uniform("roughness_value", roughness_value)
	set_uniform("roughtness_value", roughness_value) # Handle typo in shader v1
	set_uniform("world_center", world_center)
	set_uniform("seam_fix_method", seam_fix_method)
	set_uniform("max_distance", max_distance)
	set_uniform("min_amplitude_ratio", min_amplitude_ratio)
	set_uniform("parallax_scale", parallax_scale)
	set_uniform("parallax_steps", parallax_steps)

func set_uniform(uniform_name: String, value):
	if material and material.shader:
		# Check if the shader has this parameter before setting it
		var shader_params = material.shader.get_shader_uniform_list()
		for param in shader_params:
			if param.name == uniform_name:
				material.set_shader_parameter(uniform_name, value)
				break

# === Public API ===
func _get_material() -> ShaderMaterial:
	return material

func set_material_version(version: MaterialVersions):
	material_version = version

# Get property dictionary for serialization/recreation
func get_property_dict() -> Dictionary:
	var props = {}
	
	# Core properties
	props["material_version"] = material_version
	
	# Texture properties (store resource paths)
	if noise_texture:
		props["noise_texture_path"] = noise_texture.resource_path
	if normal_map_texture:
		props["normal_map_texture_path"] = normal_map_texture.resource_path
	
	# Numeric properties
	props["sphere_radius"] = sphere_radius
	props["amplitude"] = amplitude
	props["uv_scale"] = {"x": uv_scale.x, "y": uv_scale.y}
	props["mix_color"] = {"x": mix_color.r, "y": mix_color.g, "z": mix_color.b}
	props["mix_ratio"] = mix_ratio
	props["axis_scale"] = {"x": axis_scale.x, "y": axis_scale.y, "z": axis_scale.z}
	props["roughness_value"] = roughness_value
	props["world_center"] = {"x": world_center.x, "y": world_center.y, "z": world_center.z}
	props["seam_fix_method"] = seam_fix_method
	
	# V2 specific properties
	props["max_distance"] = max_distance
	props["min_amplitude_ratio"] = min_amplitude_ratio
	props["parallax_scale"] = parallax_scale
	props["parallax_steps"] = parallax_steps
	
	return props

# Create material from property dictionary
func apply_property_dict(props: Dictionary):
	# Apply material version first
	if props.has("material_version"):
		material_version = props["material_version"]
	
	# Apply texture properties
	if props.has("noise_texture_path") and props["noise_texture_path"] != "":
		noise_texture = load(props["noise_texture_path"]) as Texture2D
	if props.has("normal_map_texture_path") and props["normal_map_texture_path"] != "":
		normal_map_texture = load(props["normal_map_texture_path"]) as Texture2D
	
	# Apply all other properties
	if props.has("sphere_radius"):
		sphere_radius = props["sphere_radius"]
	if props.has("amplitude"):
		amplitude = props["amplitude"]
	if props.has("uv_scale"):
		var uv_data = props["uv_scale"]
		uv_scale = Vector2(uv_data.get("x", 1.0), uv_data.get("y", 1.0))
	if props.has("mix_color"):
		var color_data = props["mix_color"]
		mix_color = Color(color_data.get("r", 1.0), color_data.get("g", 1.0), color_data.get("b", 1.0))
	if props.has("mix_ratio"):
		mix_ratio = props["mix_ratio"]
	if props.has("axis_scale"):
		var scale_data = props["axis_scale"]
		axis_scale = Vector3(scale_data.get("x", 1.0), scale_data.get("y", 1.0), scale_data.get("z", 1.0))
	if props.has("roughness_value"):
		roughness_value = props["roughness_value"]
	if props.has("world_center"):
		var center_data = props["world_center"]
		world_center = Vector3(center_data.get("x", 0.0), center_data.get("y", 0.0), center_data.get("z", 0.0))
	if props.has("seam_fix_method"):
		seam_fix_method = props["seam_fix_method"]
	if props.has("max_distance"):
		max_distance = props["max_distance"]
	if props.has("min_amplitude_ratio"):
		min_amplitude_ratio = props["min_amplitude_ratio"]
	if props.has("parallax_scale"):
		parallax_scale = props["parallax_scale"]
	if props.has("parallax_steps"):
		parallax_steps = props["parallax_steps"]

# Utility function to check if current shader supports a parameter
func has_uniform(uniform_name: String) -> bool:
	if not material or not material.shader:
		return false
	
	var shader_params = material.shader.get_shader_uniform_list()
	for param in shader_params:
		if param.name == uniform_name:
			return true
	return false
