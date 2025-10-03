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

	lines.append("[b]NEO Summary[/b]")
	lines.append("Designation:   %s" % designation)
	lines.append("NEO Ref ID:    %s" % neo_ref_id)
	lines.append("")
	lines.append("[b]Orbit (epoch TDB: %s)[/b]" % epoch_tdb)
	lines.append("a:             %d km" % int(round(a_km)))
	lines.append("e:             %s" % e)
	lines.append("i:             %s°" % i_deg)
	lines.append("RAAN:          %s°" % raan_deg)
	lines.append("ω (arg peri):  %s°" % argp_deg)
	lines.append("M (mean anom): %s°" % M_deg)
	lines.append("")
	lines.append("[b]Physical[/b]")
	lines.append("H (mag):       %s" % H_mag)
	lines.append("Diameter:      %s km" % diameter_km)
	lines.append("Albedo pV:     %s" % albedo_text)
	lines.append("PHA:           %s" % pha_text)

	return lines

# ---- lifecycle ---------------------------------------------------------------
@onready var pick_this_button = %pick_this_button
@onready var prev_button = %prev_button
@onready var next_buttnon = %next_buttnon

func _ready() -> void:
	if DESIGNATIONS is JSON and DESIGNATIONS.data is Array:
		file_name_buffer = DESIGNATIONS.data
		print(file_name_buffer)

	if not file_name_buffer.is_empty():
		load_current_prefab()
	
	prev_button.pressed.connect(
		func():
		if file_name_buffer.is_empty(): return
		current_file = max(0, current_file - 1)
		load_current_prefab()
	)
	next_buttnon.pressed.connect(
		func():
		if file_name_buffer.is_empty(): return
		current_file = min(file_name_buffer.size() - 1, current_file + 1)
		load_current_prefab()
	)
	



func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			pass





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
