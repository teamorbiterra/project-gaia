extends Node2D

var time: float = 0.0
var a: float = 3.0   # x frequency
var b: float = 2.0   # y frequency
var delta: float = 0.0  # phase shift
var _scale: float = 150.0

func _process(delta_time: float) -> void:
	time += delta_time
	queue_redraw()

func _draw() -> void:
	var center = get_viewport_rect().size / 2
	var points: Array = []
	
	# Generate Lissajous curve
	for t in range(0, 1000):
		var theta = t / 1000.0 * TAU * 5   # loop multiple times
		var x = center.x + _scale * sin(a * theta + delta)
		var y = center.y + _scale * sin(b * theta)
		points.append(Vector2(x, y))
	
	# Draw curve
	for i in range(points.size() - 1):
		var col = Color.from_hsv(float(i) / points.size(), 1.0, 1.0, 0.8)
		draw_line(points[i], points[i + 1], col, 2.0)
	
	# Draw axis cross
	draw_line(center + Vector2(-10, 0), center + Vector2(10, 0), Color.WHITE, 2)
	draw_line(center + Vector2(0, -10), center + Vector2(0, 10), Color.WHITE, 2)

	# Info
	draw_string(ThemeDB.fallback_font, Vector2(20, 30),
		"Lissajous | a=%.1f, b=%.1f" % [a, b],HORIZONTAL_ALIGNMENT_CENTER,-1,30,Color.WHITE
		)

func _unhandled_input(event: InputEvent) -> void:
	# Drag mouse left-right to change "a"
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		a = clamp(a + event.relative.x * 0.05, 1, 10)
		b = clamp(b + event.relative.y * 0.05, 1, 10)

	# Scroll to zoom in/out
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_scale += 10
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_scale = max(20, _scale - 10)
