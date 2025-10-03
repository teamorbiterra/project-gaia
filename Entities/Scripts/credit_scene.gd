extends SceneBase
@onready var credit_label = $Control/credit_label

func _ready():
	credit_label.bbcode_enabled = true
	credit_label.add_theme_font_size_override("normal_font_size", 24)
	credit_label.add_theme_font_size_override("bold_font_size", 26)
	
	# Connect the meta_clicked signal to make links work
	credit_label.meta_clicked.connect(_on_meta_clicked)
	
	credit_label.text = """[center][font_size=64][color=#FFD700][b]TEAM ORBITERRA[/b][/color][/font_size]

[img=400x400]res://TEAM_LOGO.png[/img]

[font_size=28][color=#00D9FF]Created for NASA Space Apps Challenge 2025[/color][/font_size]

[font_size=38][color=#00D9FF][b]Connect With Us[/b][/color][/font_size]
[color=#E0E0E0][b]Email:[/b] [url=mailto:teamorbiterra@gmail.com][color=#4FC3F7]teamorbiterra@gmail.com[/color][/url]
[b]YouTube:[/b] [url=https://www.youtube.com/@TeamOrbiterra][color=#4FC3F7]youtube.com/@TeamOrbiterra[/color][/url]
[b]Documentation:[/b] [url=https://github.com/teamorbiterra/project-gaia-documentation][color=#4FC3F7]github.com/teamorbiterra/project-gaia-documentation[/color][/url][/color]

[font_size=38][color=#00D9FF][b]Special Thanks[/b][/color][/font_size]
[color=#D0D0D0]To our amazing community and supporters who made this game possible![/color]

[font_size=38][color=#00D9FF][b]Asset Credits[/b][/color][/font_size]
[color=#E0E0E0][b][color=#7FFF7F]Fonts[/color][/b]
• Righteous Font by Brian J. Bonislawsky (Astigmatic) - SIL OFL 1.1

[b][color=#7FFF7F]UI Theme[/color][/b]
• Soft Retro Theme by [url=https://intergenic.itch.io/godot-theme-soft-retro][color=#4FC3F7]intergenic[/color][/url]

[b][color=#7FFF7F]Terrain & Environment[/color][/b]
• Terrain3D by [url=https://github.com/TokisanGames/Terrain3D][color=#4FC3F7]TokisanGames[/color][/url]
• Sky3D by [url=https://github.com/TokisanGames][color=#4FC3F7]TokisanGames[/color][/url][/color]

[font_size=38][color=#00D9FF][b]Tools & Engine[/b][/color][/font_size]
[color=#E0E0E0]Made with [color=#87CEEB][b]Godot Engine 4.x[/b][/color][/color]

[font_size=32][color=#FFD700][b]Thank you for playing![/b][/color][/font_size]
[font_size=18][color=#B0B0B0]© 2025 Team Orbiterra. All rights reserved.[/color][/font_size][/center]"""

func _on_meta_clicked(meta):
	OS.shell_open(meta)
