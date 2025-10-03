extends Node
class_name NEOref

var reference_dict:Dictionary={
	 "designation": "433 Eros (A898 PA)",
	  "neo_reference_id": "2000433",
	  "epoch_tdb": 2461000.5,
	  "a_km": 218131796.59477064,
	  "e": 0.2228359407071628,
	  "i_deg": 10.82846651399785,
	  "raan_deg": 304.2701025753316,
	  "argp_deg": 178.9297536744151,
	  "M_deg": 310.5543277370992,
	  "H_mag": 10.39,
	  "diameter_km": 35.9370659687,
	  "albedo": null,
	  "pha_flag": false
}

'''
uniform sampler2D noise;
uniform sampler2D normal_map : hint_normal;
uniform float sphere_radius : hint_range(0.1, 5.0) = 1.0;
uniform float amplitude : hint_range(0.0, 2.0) = 0.3;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec3 mix_color : source_color = vec3(1.0);
uniform float mix_ratio : hint_range(0.0, 1.0) = 0.5;
uniform vec3 axis_scale = vec3(1.0, 1.0, 1.0);
uniform float roughtness_value : hint_range(0.0, 1.0) = 0.0;

// World space center control
uniform vec3 world_center = vec3(0.0, 0.0, 0.0);

// Solution selector
uniform int seam_fix_method : hint_range(0, 2) = 1;

varying vec3 local_normal;
varying vec3 world_pos_for_sampling;

'''


# Neo Shader 1
const NEO_SHADER_1 = preload("uid://dknnycxd527h4")


var designation:String
var neo_reference_id:int
var epoch_tdb:float
var a_km:float
var e:float
var i_deg:float
var raan_deg:float
var argp_deg:float
var M_deg:float
var H_mag:float
var diameter_km:float
var albedo:float
var pha_flag:bool

var data_dict:Dictionary
var path= "res://Data Processing Server/NEO Library/NEO Prefabs/"


func _init(_data_dict:Dictionary):
	data_dict=_data_dict
	for key in reference_dict.keys():
		self.set(key,data_dict.get(key,null))
	print("NEO Initialized Sucessfully")

func ShowData():
	# here prints the data
	# first print designation
	print(designation)
	print("=".repeat(50))
	for key in reference_dict.keys():
		if key=="designation":
			continue
		print(key,":",get(key))	

func _set_owner_recursive(root: Node) -> void:
	# Set owner on *descendants* only; leave root.owner = null
	for child in root.get_children():
		child.owner = root
		_set_owner_recursive(child)

func build_and_save_scene() -> void:
	var parent_node := Node3D.new()
	parent_node.name = str(self.designation)

	# --- build your hierarchy ---
	var neo_mesh_instance := MeshInstance3D.new()
	neo_mesh_instance.name = str(self.designation)+"_Mesh"
	parent_node.add_child(neo_mesh_instance)

	var neo_mesh :=BoxMesh.new()
	neo_mesh.subdivide_width=100
	neo_mesh.subdivide_height=100
	neo_mesh.subdivide_depth=100
	neo_mesh_instance.mesh = neo_mesh

	var neo_material := ShaderMaterial.new()
	neo_material.shader= NEO_SHADER_1 
	
	#region set basic shader parameters
	var noise_texture= NoiseTexture2D.new()
	var normal_texture= NoiseTexture2D.new()
	var noise_map= FastNoiseLite.new()
	
	noise_map.noise_type=FastNoiseLite.TYPE_CELLULAR
	noise_map.frequency= randf_range(0.0023,0.0057)
	
	noise_texture.noise= noise_map
	normal_texture.noise= noise_map
	
	noise_texture.seamless=true
	normal_texture.seamless=true
	noise_texture.seamless_blend_skirt=1.0
	normal_texture.seamless_blend_skirt=1.0
	normal_texture.bump_strength=32.0
	normal_texture.as_normal_map=true
	
	
	# now set shader parameters
	neo_material.set_shader_parameter("noise",noise_texture)
	neo_material.set_shader_parameter("normal_map",normal_texture)
	neo_material.set_shader_parameter("sphere_radius",remap(self.diameter_km,0.1,35.0,0.5,1.5))#based on largest and Smallest NEO discovered till now
	neo_material.set_shader_parameter("roughtness_value",1.0)
	neo_material.set_shader_parameter("mix_color",Color.DIM_GRAY)
	neo_material.set_shader_parameter("mix_ratio",0.7)
	
	
	#endregion set basic shader parameters
	# now set the shader
	#region axis correction and tilting
	var rand_axis=randi()%3
	var random_scale= Vector3.ONE
	random_scale[rand_axis]= randf_range(1.14,1.55)
	neo_material.set_shader_parameter("axis_scale",random_scale)
	
	
	# now choose a random direction to rotate the NEO
	var rand_dir=Vector3(randf_range(-1.0,1.0),randf_range(-1.0,1.0),randf_range(-1.0,1.0)).normalized()
	var rand_angle_radian= randf_range(0,TAU)
	neo_mesh_instance.rotate(rand_dir,rand_angle_radian)
	#endregion axis correction and tilting
	
	# --- critical step: assign owners to descendants ---
	neo_mesh.surface_set_material(0, neo_material)
	_set_owner_recursive(parent_node)

	# --- pack and save ---
	var packed := PackedScene.new()
	var pack_err := packed.pack(parent_node)
	if pack_err != OK:
		push_error("Failed to pack scene: %s" % pack_err)
		return

	var save_path =path+ str(self.designation)+ ".tscn"  # or wherever you want
	var save_err := ResourceSaver.save(packed, save_path)
	if save_err != OK:
		push_error("Error saving scene: %s" % save_err)
	else:
		print("Scene saved:", save_path)


func load_scene(scene_path: String):
	var scene = load(scene_path)
	if scene:
		var instance = scene.instantiate()
		add_child(instance)
		print("Loaded scene: ", scene_path)
	else:
		print("Failed to load scene")
