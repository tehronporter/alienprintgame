extends Control

var main: Node
var left_touch_id := -1
var right_touch_id := -1
var fire_touch_id := -1
var joystick_origin := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var fire_rect := Rect2()
var reload_rect := Rect2()

const JOYSTICK_RADIUS := 92.0
const GREEN := Color("#7dff35")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = _is_touch_device()
	if main != null:
		main.mobile_controls_visible = visible
	queue_redraw()

func _is_touch_device() -> bool:
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")

func _is_portrait() -> bool:
	return size.y > size.x

func _process(_delta: float) -> void:
	if main == null:
		return
	visible = main.mobile_controls_visible
	if not visible:
		return
	if _is_portrait():
		main.mobile_move_vector = Vector2.ZERO
		main.mobile_fire = false
		queue_redraw()
		return
	main.mobile_move_vector = joystick_vector
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_button_rects()

func _update_button_rects() -> void:
	var viewport_size: Vector2 = size
	var ui_scale: float = clampf(viewport_size.y / 720.0, 0.72, 1.25)
	fire_rect = Rect2(viewport_size.x - 170.0 * ui_scale, viewport_size.y - 185.0 * ui_scale, 120.0 * ui_scale, 120.0 * ui_scale)
	reload_rect = Rect2(viewport_size.x - 310.0 * ui_scale, viewport_size.y - 142.0 * ui_scale, 92.0 * ui_scale, 92.0 * ui_scale)

func _input(event: InputEvent) -> void:
	if not visible or main == null or _is_portrait():
		return
	if event is InputEventScreenTouch:
		_update_button_rects()
		if event.pressed:
			if fire_rect.has_point(event.position):
				fire_touch_id = event.index
				main.mobile_fire = true
			elif reload_rect.has_point(event.position):
				main.mobile_reload = true
			elif event.position.x < size.x * 0.46 and left_touch_id == -1:
				left_touch_id = event.index
				joystick_origin = event.position
				joystick_vector = Vector2.ZERO
			elif right_touch_id == -1:
				right_touch_id = event.index
		else:
			if event.index == fire_touch_id:
				fire_touch_id = -1
				main.mobile_fire = false
			if event.index == left_touch_id:
				left_touch_id = -1
				joystick_vector = Vector2.ZERO
			if event.index == right_touch_id:
				right_touch_id = -1
	elif event is InputEventScreenDrag:
		if event.index == left_touch_id:
			joystick_vector = (event.position - joystick_origin).limit_length(JOYSTICK_RADIUS) / JOYSTICK_RADIUS
			joystick_vector.y = -joystick_vector.y
		elif event.index == right_touch_id:
			main.mobile_look_delta += event.relative

func _draw() -> void:
	if not visible:
		return
	if _is_portrait():
		draw_rect(Rect2(Vector2.ZERO, size), Color("#010301"), true)
		var center := size * 0.5
		draw_arc(center, 130.0, 0, TAU, 40, GREEN, 6.0)
		draw_line(center + Vector2(-65, 0), center + Vector2(65, 0), GREEN, 6.0)
		draw_string(ThemeDB.fallback_font, center + Vector2(-300, 220), "ROTATE TO LANDSCAPE", HORIZONTAL_ALIGNMENT_CENTER, 600, 48, GREEN)
		return
	_update_button_rects()
	var center := joystick_origin if left_touch_id != -1 else Vector2(125, size.y - 125)
	draw_circle(center, JOYSTICK_RADIUS, Color(0.05, 0.3, 0.08, 0.22))
	draw_arc(center, JOYSTICK_RADIUS, 0, TAU, 48, GREEN, 3.0)
	var knob := center + Vector2(joystick_vector.x, -joystick_vector.y) * 48.0
	draw_circle(knob, 30.0, Color(0.49, 1.0, 0.22, 0.42))
	draw_arc(knob, 30.0, 0, TAU, 32, GREEN, 2.0)
	draw_circle(fire_rect.get_center(), 60.0, Color(0.49, 1.0, 0.22, 0.3))
	draw_arc(fire_rect.get_center(), 60.0, 0, TAU, 40, GREEN, 3.0)
	draw_string(ThemeDB.fallback_font, fire_rect.get_center() + Vector2(-25, 7), "FIRE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, GREEN)
	draw_circle(reload_rect.get_center(), 45.0, Color(0.05, 0.3, 0.08, 0.28))
	draw_arc(reload_rect.get_center(), 45.0, 0, TAU, 32, GREEN, 2.0)
	draw_string(ThemeDB.fallback_font, reload_rect.get_center() + Vector2(-28, 6), "RELOAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GREEN)
