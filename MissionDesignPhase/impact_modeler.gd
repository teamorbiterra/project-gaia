extends SceneBase
@onready var three_d_container = %threeD_container



func _ready():
	if is_node_ready():
		# check the global for active neo
		if Globals.active_neo_designation!="":
			print("just get an active neo!")
			print(Globals.active_neo_designation)
	
