extends Node3D

@onready var prevbutton: Button = %prevbutton
@onready var nextbutton: Button = %nextbutton
@onready var savebutton: Button = %savebutton


# Load JSON blob that has an exported `.data` dict
const NEODB = preload("res://Data Processing Server/Externals/neodb.json")

var reference_dict: Dictionary = {
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

var data: Dictionary = {}
var current_neo_index: int = 0
var NEOs: Array[NEOref] = []

func _ready() -> void:
	# --- Correct signal wiring ---
	prevbutton.pressed.connect(_on_prev_pressed)
	nextbutton.pressed.connect(_on_next_pressed)
	savebutton.pressed.connect(_on_save_pressed)

	# --- Load & parse ---
	if NEODB:  # assume this is a JSON resource with .data
		data = NEODB.data
		parse_object_data()

	print("Total ", NEOs.size(), " NEOs initialized")

	# Show first item if any
	if not NEOs.is_empty():
		current_neo_index = 0
		NEOs[current_neo_index].ShowData()
		print("=".repeat(50))

func _on_prev_pressed() -> void:
	if NEOs.is_empty(): return
	current_neo_index = max(0, current_neo_index - 1)
	NEOs[current_neo_index].ShowData()

func _on_next_pressed() -> void:
	if NEOs.is_empty(): return
	current_neo_index = min(NEOs.size() - 1, current_neo_index + 1)
	NEOs[current_neo_index].ShowData()

func _on_save_pressed() -> void:
	if NEOs.is_empty(): return
	# Build a fresh node tree for the currently selected NEO and save it.
	NEOs[current_neo_index].build_and_save_scene()

func parse_object_data() -> void:
	if data.has("objects") and data["objects"] is Array:
		for obj in data["objects"]:
			if obj is Dictionary:
				var neo := NEOref.new(obj)
				NEOs.append(neo)

var runing_process:=false
var running_process := false

func _input(event):
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_S and not running_process:
			running_process = true
			save_all_neos()
			
func save_all_neos() -> void:
	print("Starting save for all NEOs...")
	await get_tree().process_frame  # yield one frame before starting

	for i in NEOs.size():
		var neo = NEOs[i]
		neo.build_and_save_scene()
		
		# let engine breathe: wait 0.05 sec between saves
		await get_tree().create_timer(0.05).timeout

		print("Saved NEO ", i + 1, " / ", NEOs.size())

	print("✅ All NEOs have been saved.")
	running_process = false
