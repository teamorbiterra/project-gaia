extends Node3D
class_name PayloadTracker
const EARTHMAP_TEXTURES = preload("uid://ccyunuusom6yf")
const ROCKET_MINI = preload("uid://clwqbojrphyc2")

func _ready():
	#region adding-the-earth
	var earth:= MeshInstance3D.new()
	var earth_mesh= SphereMesh.new()
	earth_mesh.radius=1.0
	earth_mesh.height=2.0
	var earth_material= StandardMaterial3D.new()
	earth_material.albedo_texture= EARTHMAP_TEXTURES
	earth_mesh.material= earth_material
	earth.mesh= earth_mesh
	add_child(earth)
	#endregion
	
	#region adding-the-rocket
	var rocket=MeshInstance3D.new()
	rocket.mesh= ROCKET_MINI
	rocket.scale=Vector3.ONE*0.2
	add_child(rocket)
	rocket.position= Vector3(1,1,1)
	#endregion
