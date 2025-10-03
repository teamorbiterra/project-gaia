extends Node3D

var code="""
extends MissionControllerProgram
var lv:LaunchVehicle

func ready():
	lv= LaunchVehicle.new()
var time:float=0.0

func update(dt:float)->Vector3:
	lv.position.x= 2*sin(TAU*0.1*time)
	lv.position.z= 2*cos(TAU*0.1*time)
	time+=dt
	return lv.position
"""



var instance=null
func _ready():
	var program= GDScript.new()
	program.source_code= code
	var error=program.reload(false)
	if error!= OK:
		push_error("error loading code")
	else:
		print("program loaded sucessfully")
	
	#region check variables and other stuffs
	if error==OK and program.can_instantiate():
		instance= program.new()
	if instance!=null:
		print("Instance Created Sucessfully")
	
	# first call the ready method
	if instance.has_method("ready"):
		instance.call("ready")
	# now check if it have some public property called lv
	var lv= instance.get("lv")	
	if lv!=null:
		print("Successfuly accesed the lv command module")
	else:
		print("NO Launch Vehicle is there...")
	
@onready var earth = $earth
func _process(delta):
	if instance.has_method("update"):
		var pos= instance.call("update",delta)
		earth.global_position=pos
