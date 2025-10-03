extends Control

@onready var neomesh: MeshInstance3D = %NEOMESH
var shader_mat: ShaderMaterial
var is_ready: bool = false


# now an array to hold the noise types
var noise_types_text:Array[String]=[
	"Simplex",
	"Simplex Smooth",
	"Cellular",
	"Perlin",
	"Value Cubic",
	"Value"
]

var noise_fractal_types_text:Array[String]=[
	"None",
	"FBM",
	"RIDGED",
	"PING-PONG"
]

var cellular_distance_function_text:Array[String]=[
	"Euclidean",
	"Euclidean Squared",
	"Manhattan",
	"Hybrid"
]

var cellular_return_type_text:Array[String]=[
	"Cell Value",
	"Distance",
	"Distance2",
	"Distance2 Added",
	"Distance2 Subtracted",
	"Distance2 Multiplied",
	"Distance2 Divided"
]

var domain_wrap_type_text:Array[String]=[
	"Simplex",
	"Simplex Reduced",
	"Basic Grid"
]

var domain_wrap_fractal_type_text:Array[String]=[
	"None",
	"Progressive",
	"Independent"
]


# Export variables with setters that work during runtime
@export var noise_texture: NoiseTexture2D:
	set(value):
		# Disconnect from old texture if it exists
		if noise_texture and noise_texture.changed.is_connected(_on_noise_texture_changed):
			noise_texture.changed.disconnect(_on_noise_texture_changed)
		
		noise_texture = value
		
		# Connect to new texture's changed signal
		if value:
			value.changed.connect(_on_noise_texture_changed)
		
		if is_ready and shader_mat:
			shader_mat.set_shader_parameter("noise", value)

@export var normal_map: NoiseTexture2D:
	set(value):
		# Disconnect from old texture if it exists
		if normal_map and normal_map.changed.is_connected(_on_normal_map_changed):
			normal_map.changed.disconnect(_on_normal_map_changed)
		
		normal_map = value
		
		# Connect to new texture's changed signal
		if value:
			value.changed.connect(_on_normal_map_changed)
		
		if is_ready and shader_mat:
			shader_mat.set_shader_parameter("normal_map", value)

@export var sphere_radius: float = 1.0:
	set(value):
		sphere_radius = value
		if is_ready and shader_mat:
			shader_mat.set_shader_parameter("sphere_radius", value)

@export var amplitude: float = 0.3:
	set(value):
		amplitude = value
		if is_ready and shader_mat:
			shader_mat.set_shader_parameter("amplitude", value)

@export var uv_scale: Vector2 = Vector2(1, 1):
	set(value):
		uv_scale = value
		if is_ready and shader_mat:
			shader_mat.set_shader_parameter("uv_scale", value)

@export var mix_color: Color = Color(1, 1, 1):
	set(value):
		mix_color = value
		if is_ready and shader_mat:
			shader_mat.set_shader_parameter("mix_color", Vector3(value.r, value.g, value.b))

@export var mix_ratio: float = 0.5:
	set(value):
		mix_ratio = value
		if is_ready and shader_mat:
			shader_mat.set_shader_parameter("mix_ratio", value)

@export var axis_scale: Vector3 = Vector3(1, 1, 1):
	set(value):
		axis_scale = value
		if is_ready and shader_mat:
			shader_mat.set_shader_parameter("axis_scale", value)

@export var roughness_value: float = 0.7:
	set(value):
		roughness_value = value
		if is_ready and shader_mat:
			shader_mat.set_shader_parameter("roughtness_value", value)

@export var world_center: Vector3 = Vector3(0, 0, 0):
	set(value):
		world_center = value
		if is_ready and shader_mat:
			shader_mat.set_shader_parameter("world_center", value)

@export var seam_fix_method: int = 1:
	set(value):
		seam_fix_method = value
		if is_ready and shader_mat:
			shader_mat.set_shader_parameter("seam_fix_method", value)



@onready var property_control_container = %property_control_container



func _ready():
	# Try different ways to get the material
	if neomesh.material_override:
		shader_mat = neomesh.material_override as ShaderMaterial
		print("Found material_override")
	elif neomesh.get_surface_override_material(0):
		shader_mat = neomesh.get_surface_override_material(0) as ShaderMaterial
		print("Found surface_override_material")
	elif neomesh.mesh and neomesh.mesh.get_surface_count() > 0:
		shader_mat = neomesh.mesh.surface_get_material(0) as ShaderMaterial
		print("Found mesh surface material")
	
	
	if shader_mat:
		print("ShaderMaterial found successfully!")
		is_ready = true
		# Force update all parameters
		update_all_uniforms()
		# Connect to texture signals if they exist
		connect_texture_signals()
	else:
		push_error("No ShaderMaterial found on NEOMESH!")
		# Debug info
		print("neomesh.material_override: ", neomesh.material_override)
		if neomesh.mesh:
			print("Surface count: ", neomesh.mesh.get_surface_count())
			if neomesh.mesh.get_surface_count() > 0:
				print("Surface 0 material: ", neomesh.mesh.surface_get_material(0))
	
	
	##TODO: add mesh subdivision parameters
	var mesh_property_title= Label.new()
	mesh_property_title.text="Subdivisions\n(Higher Subdivision Value \nGives Better Resolution)"
	var sub_division_x_control= NumEditor.new()
	sub_division_x_control.title= "Subdivision Width:"
	sub_division_x_control.is_int=true
	sub_division_x_control.max_value=150
	sub_division_x_control.min_value=32
	sub_division_x_control.step_size=1
	
	var sub_division_y_control= sub_division_x_control.duplicate()
	sub_division_y_control.title="Subdivision Height:"
	
	var sub_division_z_control= sub_division_x_control.duplicate()
	sub_division_z_control.title="Subdivision Depth:"
	
	property_control_container.add_child(mesh_property_title)
	property_control_container.add_child(sub_division_x_control)
	property_control_container.add_child(sub_division_y_control)
	property_control_container.add_child(sub_division_z_control)
	property_control_container.add_child(HSeparator.new())
	sub_division_x_control.number_changed.connect(
		func(_number:int):
			if neomesh.mesh is BoxMesh:
				neomesh.mesh.subdivide_width= _number	
			sub_division_x_control.release_focus()
	)
	sub_division_y_control.number_changed.connect(
		func(_number:int):
			if neomesh.mesh is BoxMesh:
				neomesh.mesh.subdivide_height= _number	
			sub_division_y_control.release_focus()
	)
	sub_division_z_control.number_changed.connect(
		func(_number:int):
			if neomesh.mesh is BoxMesh:
				neomesh.mesh.subdivide_depth= _number	
			sub_division_z_control.release_focus()
	)
	
	## TODO: Axis Scale Control making
	var on_scale_changed:Callable = func(value:float, axis:String,control):
		match axis:
			"x":
				axis_scale.x=value
			"y":
				axis_scale.y=value
			"z":
				axis_scale.z=value
		control.release_focus()
	var scale_x=NumEditor.new()
	scale_x.title="Scale X"
	scale_x.min_value=0.5
	scale_x.max_value=5.0
	scale_x.step_size=0.01
	scale_x.is_float=true
	var scale_y=scale_x.duplicate()
	var scale_z= scale_x.duplicate()
	scale_y.title= "Scale Y"
	scale_z.title= "Scale Z"
	property_control_container.add_child(HSeparator.new())
	var scale_label=Label.new()
	scale_label.text="Set Scale:"
	property_control_container.add_child(scale_label)
	property_control_container.add_child(HSeparator.new())
	property_control_container.add_child(scale_x)
	property_control_container.add_child(scale_y)
	property_control_container.add_child(scale_z)
	scale_x.number_changed.connect(on_scale_changed.bind("x",scale_x))
	scale_y.number_changed.connect(on_scale_changed.bind("y",scale_y))
	scale_z.number_changed.connect(on_scale_changed.bind("z",scale_z))
	
	## TODO: set the noise texture size
	#var noise_texture_dimention_control_label=Label.new()
	#noise_texture_dimention_control_label.text= "Noise Dimension Scale:"
	#var noise_texture_scale_x=NumEditor.new()
	#noise_texture_scale_x.title= "Width 32 X"
	#noise_texture_scale_x.is_int=true
	#noise_texture_scale_x.max_value=64
	#noise_texture_scale_x.min_value=1
	#noise_texture_scale_x.step_size=1
	#var noise_texture_scale_y= noise_texture_scale_x.duplicate()
	#noise_texture_scale_y.title= "Height 32 X"
	#
	## now add the child 
	#property_control_container.add_child(noise_texture_dimention_control_label)
	#property_control_container.add_child(noise_texture_scale_x)
	#property_control_container.add_child(noise_texture_scale_y)
	#property_control_container.add_child(HSeparator.new())
	#noise_texture_scale_x.number_changed.connect(
		#func(new_value:int):
			#noise_texture.width= new_value
			#normal_map.width=new_value
	#)
	#noise_texture_scale_y.number_changed.connect(
		#func(new_value:int):
			#noise_texture.height=new_value
			#normal_map.height=new_value
	#)
	
	
	
	
	## TODO: sphere radius controller
	var sphere_radius_control= NumEditor.new()
	sphere_radius_control.title= "NEO Radius"
	property_control_container.add_child(sphere_radius_control)
	sphere_radius_control.is_float= true
	sphere_radius_control.min_value= 0.5
	sphere_radius_control.max_value=5.0
	sphere_radius_control.step_size=0.01
	sphere_radius_control.number_changed.connect(
		func(new_val:float):
			sphere_radius= new_val
			sphere_radius_control.release_focus()
	)
	
	##TODO: Amplitude controller
	var amplitude_control= NumEditor.new()
	amplitude_control.title= "Surface Bump Amplitude"
	property_control_container.add_child(amplitude_control)
	amplitude_control.is_float= true
	amplitude_control.min_value= 0.0
	amplitude_control.max_value=1.0
	amplitude_control.step_size=0.001
	amplitude_control.number_changed.connect(
		func(new_val:float):
			amplitude= new_val
			amplitude_control.release_focus()
	)
	
	## TODO: surface mix color control
	var mix_color_inner_container= HBoxContainer.new()
	var mix_color_control_label= Label.new()
	mix_color_control_label.text="Mix Color"
	var mix_color_control = ColorPickerButton.new()
	mix_color_control.custom_minimum_size = Vector2(150, 50)
	mix_color_control.size_flags_horizontal = Control.SIZE_SHRINK_END
	mix_color_control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	property_control_container.add_child(mix_color_inner_container)
	mix_color_inner_container.add_child(mix_color_control_label)
	mix_color_inner_container.add_child(mix_color_control)
	mix_color_control.size= Vector2(100,100)
	mix_color_control.color_changed.connect(
		func(color:Color):
			mix_color=color
			mix_color_control.release_focus()
	)
	## end mix color color control
	
	## TODO: mix ratio control
	var mix_ratio_control= NumEditor.new()
	mix_ratio_control.title= "Color Mix Ratio"
	property_control_container.add_child(mix_ratio_control)
	mix_ratio_control.is_float= true
	mix_ratio_control.min_value= 0.0
	mix_ratio_control.max_value=1.0
	mix_ratio_control.step_size=0.001
	mix_ratio_control.number_changed.connect(
		func(new_val:float):
			mix_ratio= new_val
			mix_ratio_control.release_focus()
	)
	
	
	
	
	## TODO roughness value control
	var roughness_value_control= NumEditor.new()
	roughness_value_control.title= "Surface Roughness"
	property_control_container.add_child(roughness_value_control)
	roughness_value_control.is_float= true
	roughness_value_control.min_value= 0.0
	roughness_value_control.max_value=1.0
	roughness_value_control.step_size=0.001
	roughness_value_control.value= roughness_value
	roughness_value_control.number_changed.connect(
		func(new_val:float):
			roughness_value= new_val
			roughness_value_control.release_focus()
	)
	property_control_container.add_child(HSeparator.new())
	## TODO: generate noise specific settings
	generate_noise_specific_settings()

func generate_noise_specific_settings():
	##TODO: add noise specific settings
	var noise_specific_settings_title= Label.new()
	noise_specific_settings_title.text="Noise Specific Settings:"
	property_control_container.add_child(noise_specific_settings_title)
	property_control_container.add_child(HSeparator.new())
	
	
	## TODO: Add a title first then the options
	var noise_type_title=Label.new()
	noise_type_title.text="Noise Types:"
	var noise_option_control = OptionButton.new()
	for noise_type in noise_types_text:
		noise_option_control.add_item(noise_type)
	noise_option_control.select(0)
	property_control_container.add_child(noise_type_title)
	property_control_container.add_child(noise_option_control)
	
	noise_option_control.item_selected.connect(
		func(id:int):
			# okay, now change the noise types for both noise texture and normal map
			noise_texture.noise.noise_type= id
			normal_map.noise.noise_type= id
			update_all_uniforms()
			noise_option_control.release_focus()
	)
	
	#TODO: add commmon properties to the noises
	var noise_seed_control= NumEditor.new()
	noise_seed_control.title="Noise Seed"
	noise_seed_control.is_float=true
	noise_seed_control.step_size=0.01
	property_control_container.add_child(noise_seed_control)
	noise_seed_control.number_changed.connect(
		func(new_value:float):
			if noise_texture!=null and normal_map!=null:
				if noise_texture.noise!=null and normal_map.noise!=null:
					noise_texture.noise.seed= round(new_value*10000)
					noise_texture.noise.seed= round(new_value*10000)
			noise_seed_control.release_focus()
	)
	
	#TODO: change noise frequency
	var noise_frequency_control= NumEditor.new()
	noise_frequency_control.title= "Noise Frequency"
	noise_frequency_control.is_float=true
	noise_frequency_control.min_value=0.0
	noise_frequency_control.max_value=100.0
	noise_frequency_control.step_size= 0.0001
	property_control_container.add_child(noise_frequency_control)
	noise_frequency_control.number_changed.connect(
		func(new_value:float):
			var mapped_value= remap(new_value,0.0,100.0,0.0004,0.01)
			if noise_texture!=null and normal_map!=null:
				if noise_texture.noise!=null and normal_map.noise!=null:
					noise_texture.noise.frequency=mapped_value
					normal_map.noise.frequency= mapped_value
			noise_frequency_control.release_focus()
	)


func connect_texture_signals():
	# Connect to noise texture changed signal
	if noise_texture and not noise_texture.changed.is_connected(_on_noise_texture_changed):
		noise_texture.changed.connect(_on_noise_texture_changed)
		print("Connected to noise_texture.changed signal")
	
	# Connect to normal map changed signal
	if normal_map and not normal_map.changed.is_connected(_on_normal_map_changed):
		normal_map.changed.connect(_on_normal_map_changed)
		print("Connected to normal_map.changed signal")

# Signal callbacks for texture changes
func _on_noise_texture_changed():
	print("Noise texture changed!")
	if is_ready and shader_mat and noise_texture:
		shader_mat.set_shader_parameter("noise", noise_texture)
		

func _on_normal_map_changed():
	print("Normal map changed!")
	if is_ready and shader_mat and normal_map:
		shader_mat.set_shader_parameter("normal_map", normal_map)

func update_all_uniforms():
	if not shader_mat:
		return
	
	shader_mat.set_shader_parameter("noise", noise_texture)
	shader_mat.set_shader_parameter("normal_map", normal_map)
	shader_mat.set_shader_parameter("sphere_radius", sphere_radius)
	shader_mat.set_shader_parameter("amplitude", amplitude)
	shader_mat.set_shader_parameter("uv_scale", uv_scale)
	shader_mat.set_shader_parameter("mix_color", Vector3(mix_color.r, mix_color.g, mix_color.b))
	shader_mat.set_shader_parameter("mix_ratio", mix_ratio)
	shader_mat.set_shader_parameter("axis_scale", axis_scale)
	shader_mat.set_shader_parameter("roughtness_value", roughness_value)
	shader_mat.set_shader_parameter("world_center", world_center)
	shader_mat.set_shader_parameter("seam_fix_method", seam_fix_method)
	print("All shader uniforms updated!")

# Alternative method: Call this manually if setters still don't work
func force_update_shader():
	if shader_mat:
		update_all_uniforms()
	else:
		print("shader_mat is null - cannot update")

# Clean up connections when the node is freed
func _exit_tree():
	if noise_texture and noise_texture.changed.is_connected(_on_noise_texture_changed):
		noise_texture.changed.disconnect(_on_noise_texture_changed)
	if normal_map and normal_map.changed.is_connected(_on_normal_map_changed):
		normal_map.changed.disconnect(_on_normal_map_changed)
