extends Node3D

var code_v1 = """
extends MissionControllerProgram

func on_load():
	Console.LogMessage.connect(
		func(msg):
			print(msg)
	)
"""


var program: MissionControllerProgram


func _ready():
	var program_script = GDScript.new()
	program_script.source_code = code_v1
	var error = program_script.reload(false)
	if error != OK:
		push_error("failed to load script, check syntax")
		return

	print("Successfully loaded the script...")

	# ✅ Directly create instance of the child script
	program = program_script.new()  

	if program.has_method("on_load"):
		program.call("on_load")
	if program.has_method("log_message"):
		program.call("log_message","calling log method","argument 1","argument 2")
	
	Console.Log("Loging messgge to console from parent script")
	
	
	
	
