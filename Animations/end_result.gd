extends Node

@onready var rich_text_label = $Control/RichTextLabel

func _ready():
	var report := """
	[center][b][color=yellow]MISSION REPORT[/color][/b][/center]
	[center][i]Operation Astra-01 : Kinetic Impactor Test[/i][/center]
	--------------------------------------------------------------
	[b]Mission Objective:[/b]  
	Deflect asteroid [color=orange]NEO-2025XQ[/color] from projected Earth-crossing trajectory.  

	[b]Launch Vehicle:[/b] Phoenix-F1 
	[b]Payload:[/b] Kinetic Impactor Module (KIM-01)  
	[b]Launch Site:[/b] Cape Horizon Spaceport  
	[b]Launch Time:[/b] 2025-09-21 04:12 UTC  

	--------------------------------------------------------------
	[b]Mission Timeline:[/b]  
	- T+00:00:00 → [color=green]Liftoff![/color]  
	- T+00:03:15 → Stage Separation Confirmed  
	- T+00:09:42 → Orbit Insertion Successful  
	- T+04:21:07 → Translunar Injection Burn Complete  
	- T+173:08:54 → Final Guidance Update Received  
	- T+173:09:02 → [color=red]Impact with NEO-2025XQ Confirmed[/color] 🚀💥🪨  

	--------------------------------------------------------------
	[b]Results:[/b]  
	- Asteroid orbital period reduced by [color=aqua]1.2%[/color]  
	- Trajectory shifted by approx. [color=aqua]37 meters[/color] at closest Earth approach  
	- [color=green]Earth impact risk: Successfully Averted[/color] 🌍✅  

	--------------------------------------------------------------
	[b]Mission Status:[/b] [color=lime]SUCCESS[/color]  
	--------------------------------------------------------------
	"""

	rich_text_label.bbcode_enabled = true
	rich_text_label.text = report
