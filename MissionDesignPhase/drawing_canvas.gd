extends Node2D
class_name DrawingCanvas

# === PARENT AND SIBLING REFERENCES ===
@onready var impact_modeler = $".."
@onready var impact_calculator = %Impact_Calculator

# === CANVAS SETTINGS ===
var canvas_size = Vector2(1920, 1080)
var margin = 50
var bg_color = Color(0.05, 0.05, 0.1)
var grid_color = Color(0.15, 0.15, 0.25, 0.5)

# === FONTS ===
var title_font: Font
var header_font: Font
var body_font: Font
var small_font: Font

# === DATA REFERENCES ===
# These will be populated when refresh_visualization() is called
var assessment: Object = null
var neo_footprint: Object = null

# === COLOR SCHEME ===
# Colors mapped to Torino Scale (0-10 hazard rating)
var danger_colors = {
	0: Color(0.2, 0.8, 0.2),   # Green - No hazard
	1: Color(0.3, 0.9, 0.3),   # Light green
	2: Color(0.5, 0.9, 0.2),   # Yellow-green
	3: Color(0.8, 0.9, 0.2),   # Yellow
	4: Color(1.0, 0.8, 0.0),   # Orange
	5: Color(1.0, 0.6, 0.0),   # Dark orange
	6: Color(1.0, 0.4, 0.0),   # Red-orange
	7: Color(1.0, 0.2, 0.0),   # Red
	8: Color(0.9, 0.0, 0.0),   # Dark red
	9: Color(0.8, 0.0, 0.2),   # Crimson
	10: Color(0.6, 0.0, 0.4)   # Purple-red - Catastrophic
}

# === INITIALIZATION ===
func _ready():
	print("DrawingCanvas: Initialized and ready")
	print("DrawingCanvas: Waiting for impact assessment data...")
	
	# Load fonts (using system default font)
	# You can replace these with custom fonts if you have .ttf files
	title_font = ThemeDB.fallback_font
	header_font = ThemeDB.fallback_font
	body_font = ThemeDB.fallback_font
	small_font = ThemeDB.fallback_font
	
	# Don't try to load data here - wait for parent to call refresh_visualization()

# === PUBLIC API ===
# Called by parent (ImpactModeler) when assessment is complete
func refresh_visualization():
	print("\n" + "=".repeat(60))
	print("DrawingCanvas: refresh_visualization() called")
	print("=".repeat(60))
	
	# Verify impact calculator exists
	if not impact_calculator:
		push_error("DrawingCanvas: Impact calculator reference is null!")
		return
	
	# Verify get_assessment method exists
	if not impact_calculator.has_method("get_assessment"):
		push_error("DrawingCanvas: get_assessment() method not found in ImpactCalculator!")
		return
	
	# Get assessment data
	assessment = impact_calculator.get_assessment()
	
	# Verify assessment is valid
	if not assessment:
		push_error("DrawingCanvas: Assessment data is null!")
		return
	
	# Get NEO footprint data
	neo_footprint = impact_calculator.neo_footprint
	
	# Verify footprint is valid
	if not neo_footprint:
		push_error("DrawingCanvas: NEO Footprint data is null!")
		return
	
	# Data loaded successfully - print verification
	print("DrawingCanvas: Data loaded successfully!")
	print("  NEO Designation: ", neo_footprint.designation)
	print("  Torino Scale: ", assessment.torino_scale, " / 10")
	print("  Collision Probability: ", snapped(assessment.collision_probability * 100, 0.001), "%")
	print("  TNT Equivalent: ", snapped(assessment.tnt_equivalent_megatons, 0.01), " megatons")
	print("  Impact Type: ", "Ocean" if assessment.is_ocean_impact else "Land")
	
	# Trigger redraw
	print("DrawingCanvas: Requesting redraw...")
	queue_redraw()

# === MAIN DRAWING FUNCTION ===
func _draw():
	# Verify data exists before attempting to draw
	if not assessment or not neo_footprint:
		# Draw a "waiting for data" message if data isn't ready yet
		draw_rect(Rect2(Vector2.ZERO, canvas_size), bg_color, true)
		draw_waiting_screen()
		return
	
	print("DrawingCanvas: Drawing visualization...")
	
	# Draw all visualization panels
	draw_background()
	draw_grid()
	draw_title_panel()
	draw_risk_gauge(Vector2(100, 150))
	draw_energy_comparison(Vector2(100, 400))
	draw_impact_zones(Vector2(650, 150))
	draw_orbital_data(Vector2(1200, 150))
	draw_casualties_chart(Vector2(650, 600))
	draw_timeline(Vector2(100, 850))
	
	print("DrawingCanvas: Visualization complete!")

# === DRAWING FUNCTIONS ===

# Draw background
func draw_background():
	draw_rect(Rect2(Vector2.ZERO, canvas_size), bg_color, true)

# Draw grid for visual structure
func draw_grid():
	var grid_spacing = 50
	
	# Vertical lines
	for x in range(0, int(canvas_size.x), grid_spacing):
		draw_line(Vector2(x, 0), Vector2(x, canvas_size.y), grid_color, 1)
	
	# Horizontal lines
	for y in range(0, int(canvas_size.y), grid_spacing):
		draw_line(Vector2(0, y), Vector2(canvas_size.x, y), grid_color, 1)

# Draw waiting screen when data not yet loaded
func draw_waiting_screen():
	var center = canvas_size / 2
	var box_size = Vector2(600, 100)
	var box_pos = center - box_size / 2
	
	# Draw waiting box
	draw_rect(Rect2(box_pos, box_size), Color(0.1, 0.1, 0.2, 0.9), true)
	draw_rect(Rect2(box_pos, box_size), Color(0.4, 0.4, 0.5), false, 3)
	
	# Draw animated loading indicator
	var dot_count = int(Time.get_ticks_msec() / 500) % 4
	var loading_text_width = 300 + (dot_count * 20)
	var loading_pos = center - Vector2(loading_text_width / 2, 10)
	draw_rect(Rect2(loading_pos, Vector2(loading_text_width, 20)), Color(0.5, 0.7, 1.0), true)

# Draw title panel with NEO designation
func draw_title_panel():
	var title_pos = Vector2(canvas_size.x / 2, 50)
	var title = "ASTEROID IMPACT ASSESSMENT: " + str(neo_footprint.designation)
	
	# Title background
	var title_size = Vector2(800, 60)
	var title_rect = Rect2(title_pos - title_size / 2, title_size)
	draw_rect(title_rect, Color(0.1, 0.1, 0.2, 0.8), true)
	draw_rect(title_rect, Color(0.3, 0.3, 0.5), false, 2)
	
	# Draw title text
	var text_color = danger_colors[assessment.torino_scale]
	var font_size = 32
	draw_string(title_font, title_pos - Vector2(title.length() * 9.0, -15), title, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)

# Draw risk assessment gauge (Torino Scale)
func draw_risk_gauge(pos: Vector2):
	var panel_size = Vector2(500, 200)
	
	# Panel background
	draw_panel_background(pos, panel_size, "RISK ASSESSMENT")
	
	# === Torino Scale Gauge ===
	var gauge_center = pos + Vector2(100, 120)
	var gauge_radius = 60
	
	# Draw gauge background
	draw_arc(gauge_center, gauge_radius, 0, TAU, 32, Color(0.2, 0.2, 0.3), 15, true)
	
	# Draw colored segments (0-10)
	for i in range(11):
		var angle_start = (i / 10.0) * PI
		var angle_end = ((i + 1) / 10.0) * PI
		var color = danger_colors[i]
		draw_arc(gauge_center, gauge_radius, angle_start, angle_end, 8, color, 15, true)
	
	# Draw needle pointing to current Torino scale
	var needle_angle = (assessment.torino_scale / 10.0) * PI
	var needle_end = gauge_center + Vector2(cos(needle_angle), sin(needle_angle)) * (gauge_radius - 10)
	draw_line(gauge_center, needle_end, Color.WHITE, 4)
	draw_circle(gauge_center, 8, Color.WHITE)
	
	# Draw scale number
	var scale_pos = gauge_center + Vector2(0, 40)
	draw_string(body_font, scale_pos, str(assessment.torino_scale) + " / 10", HORIZONTAL_ALIGNMENT_CENTER, -1, 24, danger_colors[assessment.torino_scale])
	
	# === Collision Probability Bar ===
	var prob_pos = pos + Vector2(250, 60)
	var prob_width = 200
	var prob_height = 30
	
	# Label
	draw_string(body_font, prob_pos - Vector2(0, 20), "Collision Probability", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	
	# Background
	draw_rect(Rect2(prob_pos, Vector2(prob_width, prob_height)), Color(0.2, 0.2, 0.3), true)
	draw_rect(Rect2(prob_pos, Vector2(prob_width, prob_height)), Color(0.4, 0.4, 0.5), false, 2)
	
	# Fill bar based on probability
	var prob_fill = assessment.collision_probability * prob_width
	var prob_color = Color(1, 0, 0) if assessment.collision_probability > 0.01 else Color(1, 0.8, 0)
	draw_rect(Rect2(prob_pos, Vector2(prob_fill, prob_height)), prob_color, true)
	
	# Percentage text
	var prob_text = str(snapped(assessment.collision_probability * 100, 0.001)) + "%"
	draw_string(body_font, prob_pos + Vector2(prob_width + 10, 20), prob_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	
	# === MOID Indicator ===
	var moid_pos = pos + Vector2(250, 120)
	
	# Label
	draw_string(body_font, moid_pos - Vector2(0, 20), "MOID (Minimum Distance)", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	
	var moid_normalized = clamp(assessment.moid_km / 1000000.0, 0, 1)  # Normalize to 1 million km
	var moid_bar_width = (1.0 - moid_normalized) * 200  # Inverse - closer is more dangerous
	draw_rect(Rect2(moid_pos, Vector2(moid_bar_width, 20)), Color(0, 0.8, 1), true)
	
	# Distance text
	var moid_text = str(snapped(assessment.moid_km, 0.1)) + " km"
	draw_string(body_font, moid_pos + Vector2(210, 15), moid_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

# Draw energy comparison chart
func draw_energy_comparison(pos: Vector2):
	var panel_size = Vector2(500, 400)
	draw_panel_background(pos, panel_size, "IMPACT ENERGY")
	
	# Bar chart comparing to known events
	var comparisons = [
		{"name": "Hiroshima", "value": 0.015, "color": Color(0.5, 0.5, 0.5)},
		{"name": "Tsar Bomba", "value": 50, "color": Color(0.8, 0.4, 0)},
		{"name": "Tunguska", "value": 10, "color": Color(0.9, 0.6, 0)},
		{"name": "Chicxulub", "value": 100000000, "color": Color(0.5, 0, 0.5)},
		{"name": "This NEO", "value": assessment.tnt_equivalent_megatons, 
		 "color": danger_colors[assessment.torino_scale]}
	]
	
	# Find max for scaling (use log scale)
	var max_val = 0.0
	for item in comparisons:
		if item.value > max_val:
			max_val = item.value
	
	var bar_start_x = pos.x + 20
	var bar_width = 80
	var bar_spacing = 95
	var max_bar_height = 300
	
	# Draw bars
	for i in range(comparisons.size()):
		var item = comparisons[i]
		var bar_x = bar_start_x + i * bar_spacing
		var bar_y = pos.y + panel_size.y - 50
		
		# Use logarithmic scale for better visualization
		var log_height = (log(item.value + 1) / log(max_val + 1)) * max_bar_height
		
		# Draw bar
		draw_rect(Rect2(Vector2(bar_x, bar_y - log_height), 
						Vector2(bar_width, log_height)), 
				  item.color, true)
		draw_rect(Rect2(Vector2(bar_x, bar_y - log_height), 
						Vector2(bar_width, log_height)), 
				  Color.WHITE, false, 2)
		
		# Draw event name label
		draw_string(small_font, Vector2(bar_x + 5, bar_y + 20), item.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		
		# Draw value label
		var value_text = ""
		if item.value >= 1000000:
			value_text = str(snapped(item.value / 1000000, 0.1)) + "M MT"
		elif item.value >= 1000:
			value_text = str(snapped(item.value / 1000, 0.1)) + "K MT"
		else:
			value_text = str(snapped(item.value, 0.01)) + " MT"
		
		draw_string(small_font, Vector2(bar_x + 5, bar_y - log_height - 10), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, item.color)

# Draw impact zones (damage radii)
func draw_impact_zones(pos: Vector2):
	var panel_size = Vector2(500, 400)
	draw_panel_background(pos, panel_size, "IMPACT ZONES")
	
	var center = pos + panel_size / 2 + Vector2(0, 20)
	var zone_scale = 1.5  # Scale factor for visualization (renamed to avoid shadowing)
	
	# Define damage zones (draw from largest to smallest)
	var zones = [
		{"radius": assessment.moderate_damage_radius_km * zone_scale, 
		 "color": Color(1, 0.8, 0, 0.3), "label": "Moderate", "km": assessment.moderate_damage_radius_km},
		{"radius": assessment.severe_damage_radius_km * zone_scale, 
		 "color": Color(1, 0.4, 0, 0.4), "label": "Severe", "km": assessment.severe_damage_radius_km},
		{"radius": assessment.total_destruction_radius_km * zone_scale, 
		 "color": Color(1, 0, 0, 0.5), "label": "Total", "km": assessment.total_destruction_radius_km},
		{"radius": assessment.crater_diameter_km * zone_scale / 2, 
		 "color": Color(0.3, 0.1, 0, 0.7), "label": "Crater", "km": assessment.crater_diameter_km}
	]
	
	# Draw concentric circles for damage zones
	for zone in zones:
		if zone.radius > 0:
			draw_circle(center, zone.radius, zone.color)
			draw_arc(center, zone.radius, 0, TAU, 32, Color.WHITE, 2, false)
	
	# Draw thermal radiation radius (dashed circle)
	var thermal_radius = assessment.thermal_radiation_radius_km * zone_scale
	if thermal_radius > 0:
		draw_dashed_circle(center, thermal_radius, Color(1, 0.5, 0, 0.6))
	
	# Draw impact point
	draw_circle(center, 5, Color.WHITE)
	draw_circle(center, 3, Color.RED)
	
	# Draw legend
	var legend_x = pos.x + 20
	var legend_y = pos.y + 60
	var legend_spacing = 25
	
	for i in range(zones.size()):
		var zone = zones[i]
		var y = legend_y + i * legend_spacing
		
		# Color indicator
		draw_rect(Rect2(Vector2(legend_x, y), Vector2(20, 15)), zone.color, true)
		draw_rect(Rect2(Vector2(legend_x, y), Vector2(20, 15)), Color.WHITE, false, 1)
		
		# Label text
		var label_text = zone.label + ": " + str(snapped(zone.km, 0.1)) + " km"
		draw_string(small_font, Vector2(legend_x + 25, y + 12), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	
	# Thermal radiation label
	if thermal_radius > 0:
		var y = legend_y + zones.size() * legend_spacing
		draw_line(Vector2(legend_x, y + 7), Vector2(legend_x + 20, y + 7), Color(1, 0.5, 0), 2)
		var thermal_text = "Thermal: " + str(snapped(assessment.thermal_radiation_radius_km, 0.1)) + " km"
		draw_string(small_font, Vector2(legend_x + 25, y + 12), thermal_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.5, 0))
	
	# Scale indicator
	var scale_length = 50 * zone_scale
	var scale_pos = center + Vector2(-100, 150)
	draw_line(scale_pos, scale_pos + Vector2(scale_length, 0), Color.WHITE, 3)
	draw_line(scale_pos, scale_pos + Vector2(0, -10), Color.WHITE, 3)
	draw_line(scale_pos + Vector2(scale_length, 0), 
			  scale_pos + Vector2(scale_length, -10), Color.WHITE, 3)
	
	# Scale text
	draw_string(small_font, scale_pos + Vector2(scale_length / 2 - 15, -15), "50 km", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)

# Draw orbital parameters table
func draw_orbital_data(pos: Vector2):
	var panel_size = Vector2(650, 400)
	draw_panel_background(pos, panel_size, "ORBITAL PARAMETERS")
	
	var data_start = pos + Vector2(20, 50)
	var line_height = 35
	var col1_x = 0
	var col2_x = 300
	
	# Prepare orbital data rows
	var orbital_data = [
		["Semi-major Axis:", str(snapped(neo_footprint.a_km, 0.01)) + " km"],
		["Eccentricity:", str(snapped(neo_footprint.e, 0.0001))],
		["Inclination:", str(snapped(neo_footprint.i_deg, 0.01)) + "°"],
		["Orbital Period:", str(snapped(neo_footprint.orbital_period / 31536000, 0.01)) + " years"],
		["Perihelion:", str(snapped(neo_footprint.perihelion_distance, 0.01)) + " km"],
		["Aphelion:", str(snapped(neo_footprint.aphelion_distance, 0.01)) + " km"],
		["Velocity:", str(snapped(neo_footprint.orbital_velocity, 0.01)) + " km/s"],
		["Diameter:", str(snapped(neo_footprint.diameter_km, 0.001)) + " km"],
		["Mass:", str(snapped(assessment.neo_mass_kg / 1e12, 0.01)) + " trillion kg"],
		["Impact Velocity:", str(snapped(assessment.impact_velocity_km_s, 0.1)) + " km/s"]
	]
	
	# Draw data rows
	for i in range(orbital_data.size()):
		var _row = orbital_data[i]  # Prefix with underscore to indicate intentionally unused
		
		# Define box sizes
		var label_size = Vector2(280, 25)
		var value_size = Vector2(320, 25)
		
		# Draw label box
		draw_rect(Rect2(data_start + Vector2(col1_x, i * line_height), label_size), 
				  Color(0.15, 0.15, 0.25, 0.8), true)
		
		# Draw value box
		draw_rect(Rect2(data_start + Vector2(col2_x, i * line_height), value_size), 
				  Color(0.2, 0.25, 0.35, 0.8), true)
		
		# Draw borders
		draw_rect(Rect2(data_start + Vector2(col1_x, i * line_height), label_size), 
				  Color(0.4, 0.4, 0.5), false, 1)
		draw_rect(Rect2(data_start + Vector2(col2_x, i * line_height), value_size), 
				  Color(0.4, 0.4, 0.5), false, 1)
		
		# Draw text labels
		draw_string(small_font, data_start + Vector2(col1_x + 5, i * line_height + 17), 
					orbital_data[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.8, 0.9))
		
		draw_string(small_font, data_start + Vector2(col2_x + 5, i * line_height + 17), 
					orbital_data[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1)) 
	for i in range(orbital_data.size()):
		var row = orbital_data[i]
		
		# Define box sizes
		var label_size = Vector2(280, 25)
		var value_size = Vector2(320, 25)
		
		# Draw label box
		draw_rect(Rect2(data_start + Vector2(col1_x, i * line_height), label_size), 
				  Color(0.15, 0.15, 0.25, 0.8), true)
		
		# Draw value box
		draw_rect(Rect2(data_start + Vector2(col2_x, i * line_height), value_size), 
				  Color(0.2, 0.25, 0.35, 0.8), true)
		
		# Draw borders
		draw_rect(Rect2(data_start + Vector2(col1_x, i * line_height), label_size), 
				  Color(0.4, 0.4, 0.5), false, 1)
		draw_rect(Rect2(data_start + Vector2(col2_x, i * line_height), value_size), 
				  Color(0.4, 0.4, 0.5), false, 1)

# Draw casualties chart
func draw_casualties_chart(pos: Vector2):
	var panel_size = Vector2(500, 200)
	draw_panel_background(pos, panel_size, "CASUALTY ESTIMATES")
	
	var chart_center = pos + Vector2(150, 120)
	var chart_radius = 70
	
	# Draw impact type indicator (ocean vs land)
	var type_color = Color(0.2, 0.5, 1) if assessment.is_ocean_impact else Color(0.6, 0.4, 0.2)
	draw_circle(chart_center, chart_radius + 10, type_color.darkened(0.5))
	
	# Draw impact type label
	var type_text = "Ocean Impact" if assessment.is_ocean_impact else "Land Impact"
	draw_string(body_font, pos + Vector2(20, 50), type_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, type_color.lightened(0.3))
	
	# Calculate casualty breakdown
	var immediate = assessment.estimated_immediate_casualties
	var _delayed = assessment.estimated_total_casualties - immediate  # Prefix with underscore
	var total = float(assessment.estimated_total_casualties)
	
	# Draw pie chart
	if total > 0:
		var immediate_angle = (immediate / total) * TAU
		
		# Immediate casualties (red)
		draw_circle_arc_poly(chart_center, chart_radius, 0, immediate_angle, Color(1, 0.2, 0.2))
		
		# Delayed casualties (orange)
		draw_circle_arc_poly(chart_center, chart_radius, immediate_angle, TAU, Color(1, 0.6, 0.2))
		
		# Draw outline
		draw_arc(chart_center, chart_radius, 0, TAU, 32, Color.WHITE, 2, false)
	else:
		# No casualties expected (green circle)
		draw_circle(chart_center, chart_radius, Color(0.2, 0.8, 0.2))
	
	# Draw statistics boxes
	var numbers_pos = pos + Vector2(280, 70)
	var num_line_height = 40
	
	# Population exposed
	draw_stat_box(numbers_pos, "Population Exposed", 
				  str(assessment.population_in_blast_radius), Color(0.8, 0.8, 1))
	
	# Immediate casualties
	draw_stat_box(numbers_pos + Vector2(0, num_line_height), "Immediate Casualties", 
				  str(immediate), Color(1, 0.3, 0.3))
	
	# Total casualties
	draw_stat_box(numbers_pos + Vector2(0, num_line_height * 2), "Total Casualties", 
				  str(assessment.estimated_total_casualties), Color(1, 0.6, 0.3))

# Draw impact event timeline
func draw_timeline(pos: Vector2):
	var panel_size = Vector2(1720, 150)
	draw_panel_background(pos, panel_size, "IMPACT EVENT TIMELINE")
	
	var timeline_start = pos + Vector2(50, 80)
	var timeline_length = 1600
	
	# Draw timeline base
	draw_line(timeline_start, timeline_start + Vector2(timeline_length, 0), 
			  Color.WHITE, 3)
	
	# Define timeline events
	var events = [
		{"time": 0.0, "label": "Approach", "color": Color(0, 0.8, 1)},
		{"time": 0.25, "label": "Atmosphere Entry", "color": Color(1, 0.8, 0)},
		{"time": 0.5, "label": "IMPACT", "color": Color(1, 0, 0)},
		{"time": 0.6, "label": "Fireball", "color": Color(1, 0.5, 0)},
		{"time": 0.7, "label": "Air Blast", "color": Color(1, 0.8, 0.2)},
		{"time": 0.75, "label": "Seismic Wave", "color": Color(0.8, 0.4, 0)},
		{"time": 0.85, "label": "Tsunami (if ocean)", "color": Color(0.2, 0.5, 1)}
	]
	
	# Draw events on timeline
	for event in events:
		var event_x = timeline_start.x + event.time * timeline_length
		var event_pos = Vector2(event_x, timeline_start.y)
		
		# Draw event marker
		draw_line(event_pos, event_pos + Vector2(0, -30), event.color, 3)
		draw_circle(event_pos, 6, event.color)
		draw_circle(event_pos, 6, Color.WHITE, false, 2)
		
		# Draw event label
		draw_string(small_font, event_pos + Vector2(-30, -40), event.label, 
					HORIZONTAL_ALIGNMENT_CENTER, 80, 12, event.color)
		
		# Highlight impact moment with pulsing effect
		if event.label == "IMPACT":
			var pulse = abs(sin(Time.get_ticks_msec() * 0.003)) * 0.5
			draw_circle(event_pos, 12 + pulse * 5, Color(1, 0, 0, 0.3 + pulse * 0.3))

# === HELPER DRAWING FUNCTIONS ===

# Draw panel background with title
func draw_panel_background(pos: Vector2, size: Vector2, title: String):
	# Panel background
	draw_rect(Rect2(pos, size), Color(0.08, 0.08, 0.15, 0.9), true)
	draw_rect(Rect2(pos, size), Color(0.3, 0.3, 0.5), false, 2)
	
	# Title bar
	var title_height = 35
	draw_rect(Rect2(pos, Vector2(size.x, title_height)), Color(0.15, 0.15, 0.25), true)
	draw_rect(Rect2(pos, Vector2(size.x, title_height)), Color(0.4, 0.4, 0.6), false, 2)
	
	# Draw title text
	draw_string(header_font, pos + Vector2(20, 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.9, 0.9, 1))

# Draw a statistic box with label and value
func draw_stat_box(pos: Vector2, label: String, value: String, color: Color):
	var box_size = Vector2(200, 30)
	
	# Background
	draw_rect(Rect2(pos, box_size), Color(0.1, 0.1, 0.2), true)
	draw_rect(Rect2(pos, box_size), color, false, 2)
	
	# Label text
	draw_string(small_font, pos + Vector2(5, 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.8, 0.9))
	
	# Value text
	draw_string(body_font, pos + Vector2(5, 25), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)

# Draw a dashed circle
func draw_dashed_circle(center: Vector2, radius: float, color: Color):
	var segments = 32
	var dash_length = 0.7  # Proportion of segment that is drawn
	
	for i in range(segments):
		var angle1 = (i / float(segments)) * TAU
		var angle2 = ((i + dash_length) / float(segments)) * TAU
		
		draw_arc(center, radius, angle1, angle2, 3, color, 2, false)

# Draw a filled arc (for pie charts)
func draw_circle_arc_poly(center: Vector2, radius: float, angle_from: float, angle_to: float, color: Color):
	var nb_points = 32
	var points_arc = PackedVector2Array()
	
	# Start from center
	points_arc.push_back(center)
	
	# Build arc points
	var angle_step = (angle_to - angle_from) / nb_points
	for i in range(nb_points + 1):
		var angle = angle_from + i * angle_step
		points_arc.push_back(center + Vector2(cos(angle), sin(angle)) * radius)
	
	# Draw filled polygon
	draw_colored_polygon(points_arc, color)

# === DEBUG FUNCTIONS ===

# Force redraw (can be called from console for debugging)
func force_redraw():
	print("DrawingCanvas: Force redraw requested")
	queue_redraw()

# Print current data status
func print_data_status():
	print("\n=== DrawingCanvas Data Status ===")
	print("Assessment exists: ", assessment != null)
	print("NEO Footprint exists: ", neo_footprint != null)
	
	if assessment:
		print("Torino Scale: ", assessment.torino_scale)
		print("Collision Probability: ", assessment.collision_probability)
	
	if neo_footprint:
		print("NEO Designation: ", neo_footprint.designation)
		print("Diameter: ", neo_footprint.diameter_km, " km")
