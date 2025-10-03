extends SceneBase

var reference_dict := {
	"designation": "433 Eros (A898 PA)",
	"neo_reference_id": "2000433",
	"epoch_tdb": 2461000.5,
	"a_km": 218131796.59477064,
	"e": 0.22283594070716281,
	"i_deg": 10.828466513997849,
	"raan_deg": 304.27010257533158,
	"argp_deg": 178.92975367441511,
	"M_deg": 310.55432773709919,
	"H_mag": 10.39,
	"diameter_km": 35.9370659687,
	"albedo": null,
	"pha_flag": false
}

const DESIGNATIONS   = preload("res://Data Processing Server/Externals/designations.json")
const REFRACTED_DATA = preload("res://Data Processing Server/Externals/refracted_data.json")

var prefab_dir := "res://Data Processing Server/NEO Library/NEO Prefabs/"
@onready var label: RichTextLabel = %label
@onready var prefab_container := %PrefabContainer

var file_name_buffer: Array = []
var current_file := 0
var current_instance: Node3D = null

# ---- helpers for refraction/formatting --------------------------------------
#region formatting NEO information
const AU_IN_KM := 149597870.7

# Map possible incoming keys → reference keys
const KEY_ALIASES := {
	"designation": ["designation", "name", "full_name", "des"],
	"neo_reference_id": ["neo_reference_id", "neo_ref_id", "id", "spkid"],
	"epoch_tdb": ["epoch_tdb", "epoch_jd_tdb", "epoch_jd", "jd_tdb", "epoch"],
	"a_km": ["a_km", "a", "semi_major_axis_km", "semi_major_axis_au"],
	"e": ["e", "ecc", "eccentricity"],
	"i_deg": ["i_deg", "inc_deg", "inclination_deg", "i"],
	"raan_deg": ["raan_deg", "omega_node_deg", "raan", "Omega"],
	"argp_deg": ["argp_deg", "w_deg", "arg_periapsis_deg", "argp"],
	"M_deg": ["M_deg", "mean_anomaly_deg", "M"],
	"H_mag": ["H_mag", "H", "absolute_magnitude"],
	"diameter_km": ["diameter_km", "D_km", "diameter", "est_diameter_km"],
	"albedo": ["albedo", "pV", "albedo_pv", "geometric_albedo"],
	"pha_flag": ["pha_flag", "potentially_hazardous", "is_pha", "pha"]
}

func alias_get(src: Dictionary, keys: Array) -> Variant:
	for k in keys:
		if src.has(k) and src[k] != null:
			return src[k]
	return null

func to_f64(v) -> float:
	if typeof(v) == TYPE_FLOAT: return v
	if typeof(v) == TYPE_INT: return float(v)
	if typeof(v) == TYPE_STRING:
		var p = v.strip_edges()
		if p == "": return NAN
		return float(p)
	return NAN

func degrees(v) -> float:
	return to_f64(v)

func km_from_au_or_km(v, key_name: String) -> float:
	# If the source looked like AU (by alias name), convert; else return as-is (km)
	if key_name.find("au") != -1:       # alias string has "au" -> treat as AU
		return to_f64(v) * AU_IN_KM
	return to_f64(v)

func refract_dict(src_raw: Variant) -> Dictionary:
	# Accept Dictionary or JSONResource.data item that’s already a Dictionary
	var src = src_raw if typeof(src_raw) == TYPE_DICTIONARY else {}
	var out := {}
	for ref_key in reference_dict.keys():
		var aliases: Array = KEY_ALIASES.get(ref_key, [ref_key])
		var val = null

		# Special handling for a_km: could arrive as AU or KM depending on alias hit
		if ref_key == "a_km":
			var found_key := ""
			for k in aliases:
				if src.has(k) and src[k] != null:
					found_key = k
					val = src[k]
					break
			if val != null:
				out[ref_key] = km_from_au_or_km(val, found_key)
			else:
				out[ref_key] = reference_dict[ref_key]
			continue

		# Default path
		val = alias_get(src, aliases)
		if val == null:
			out[ref_key] = reference_dict[ref_key]
			continue

		match ref_key:
			"i_deg", "raan_deg", "argp_deg", "M_deg":
				out[ref_key] = degrees(val)
			"H_mag", "e", "epoch_tdb", "diameter_km", "a_km":
				out[ref_key] = to_f64(val)
			"pha_flag":
				out[ref_key] = bool(val)
			_:
				out[ref_key] = val
	return out

func human_lines(d: Dictionary) -> Array[String]:
	var lines: Array[String] = []

	var designation     := str(d.get("designation"))
	var neo_ref_id      := str(d.get("neo_reference_id"))
	var epoch_tdb       := str(d.get("epoch_tdb"))
	var a_km            := float(d.get("a_km", 0.0))
	var e               := str(d.get("e"))
	var i_deg           := str(d.get("i_deg"))
	var raan_deg        := str(d.get("raan_deg"))
	var argp_deg        := str(d.get("argp_deg"))
	var M_deg           := str(d.get("M_deg"))
	var H_mag           := str(d.get("H_mag"))
	var diameter_km     := str(d.get("diameter_km"))
	var albedo_text     := "—" if d.get("albedo") == null else str(d.get("albedo"))
	var pha_text        := "Yes" if d.get("pha_flag") else "No"
	lines.append("[color=cyan][b]Source Note[/b][/color]")
	lines.append("[color=gray]Real data from NASA NeoWs (api.nasa.gov). Endpoint: /neo/browse[/color]")
	lines.append("[color=gray]generated_utc: 2025-10-02T05:21:08Z[/color]\n")

	lines.append("[color=cyan][b]NEO Summary[/b][/color]")
	lines.append("[color=white]Designation:[/color]   [color=green]%s[/color]" % designation)
	lines.append("[color=white]NEO Ref ID:[/color]    [color=green]%s[/color]" % neo_ref_id)
	lines.append("")

	lines.append("[color=cyan][b]Orbit (epoch TDB: %s)[/b][/color]" % epoch_tdb)
	lines.append("[color=white]a:[/color]             [color=orange]%d km[/color]" % int(round(a_km)))
	lines.append("[color=white]e:[/color]             [color=orange]%s[/color]" % e)
	lines.append("[color=white]i:[/color]             [color=orange]%s°[/color]" % i_deg)
	lines.append("[color=white]RAAN:[/color]          [color=orange]%s°[/color]" % raan_deg)
	lines.append("[color=white]ω (arg peri):[/color]  [color=orange]%s°[/color]" % argp_deg)
	lines.append("[color=white]M (mean anom):[/color] [color=orange]%s°[/color]" % M_deg)
	lines.append("")

	lines.append("[color=cyan][b]Physical Information[/b][/color]")
	lines.append("[color=white]H (mag):[/color]        [color=orange]%s[/color]" % H_mag)
	lines.append("[color=white]Diameter:[/color]       [color=orange]%s km[/color]" % diameter_km)
	lines.append("[color=white]Albedo pV:[/color]      [color=orange]%s[/color]" % albedo_text)
	lines.append("[color=white]Potentially Hazardous:[/color] [color=red][b]%s[/b][/color]" % pha_text)
	lines.append("")

	lines.append("[color=red][b]Attention![/b][/color] [color=yellow]The NEO view is not physically accurate.[/color]")
	lines.append("[color=gray]It is procedurally generated from noise, although the diameters are scaled according to the actual values.[/color]")
	return lines


#endregion formating neo info


# ---- lifecycle ---------------------------------------------------------------
@onready var next_button = %next_button
@onready var previous_button = %previous_button
@onready var pick_this_button = %pick_this_button
@onready var back_button = %back_button


func _ready() -> void:
	if DESIGNATIONS is JSON and DESIGNATIONS.data is Array:
		file_name_buffer = DESIGNATIONS.data
		print(file_name_buffer)

	if not file_name_buffer.is_empty():
		load_current_prefab()
	
	previous_button.pressed.connect(
		func():
		if file_name_buffer.is_empty(): return
		current_file = max(0, current_file - 1)
		load_current_prefab()
	)
	next_button.pressed.connect(
		func():
		if file_name_buffer.is_empty(): return
		current_file = min(file_name_buffer.size() - 1, current_file + 1)
		load_current_prefab()
	)
	pick_this_button.pressed.connect(
		func():
		Globals.active_neo_designation= file_name_buffer[current_file]
		print("NEO Selected:",Globals.active_neo_designation)
		print("Doing Further Works...")
		SceneManager.load_composition(SceneManager.Composition.IMPACT_MODELING_COMPOSITION)		
	)
	back_button.pressed.connect(
		func():
		SceneManager.load_composition(SceneManager.Composition.GAME_MODE_SELECTION)
		Globals.active_neo_designation=""
	)
	
	
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			pass


#region loading and clearing current prefab

func load_current_prefab() -> void:
	if current_file < 0 or current_file >= file_name_buffer.size():
		push_warning("Index out of range for DESIGNATIONS")
		return

	var prefab_name := str(file_name_buffer[current_file], ".tscn")
	print("Loading NEO:", prefab_name)

	_clear_prefab_container()

	var neo_scene: PackedScene = load(prefab_dir + prefab_name)
	if neo_scene and neo_scene.can_instantiate():
		current_instance = neo_scene.instantiate()
		prefab_container.add_child(current_instance)

		# UI: show refracted data nicely
		if REFRACTED_DATA is JSON and REFRACTED_DATA.data is Array and current_file < REFRACTED_DATA.data.size():
			var src_item = REFRACTED_DATA.data[current_file]
			var refracted := refract_dict(src_item)
			label.clear()
			label.bbcode_enabled = true
			for line in human_lines(refracted):
				label.append_text(line + "\n")
		else:
			label.clear()
			label.append_text("No refracted data available for index " + str(current_file))
	else:
		push_warning("Could not load prefab: " + prefab_name)

func _clear_prefab_container() -> void:
	for child in prefab_container.get_children():
		child.queue_free()
	current_instance = null

#endregion loading and clearing current prefab
