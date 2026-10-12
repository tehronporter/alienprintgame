extends Control

var main: Node
var left_touch_id := -1
var right_touch_id := -1
var fire_touch_id := -1
var joystick_origin := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var fire_rect := Rect2()
var reload_rect := Rect2()
var jump_rect := Rect2()
var weapon_rect := Rect2()
var sprint_rect := Rect2()
var aim_rect := Rect2()
var pause_rect := Rect2()
var was_portrait := false

const JOYSTICK_RADIUS := 92.0
const FONT = preload("res://assets/fonts/Kalam-Regular.ttf")
const GREEN := Color("#7dff35")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = _is_touch_device()
	if main != null:
		main.mobile_controls_visible = visible
		if visible and main.settings_panel != null:
			main.settings_panel.visible = false
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
		reset_touches()
		return
	if main.settings_panel != null and main.settings_panel.visible and not main.paused:
		main.settings_panel.visible = false
	if _is_portrait():
		reset_touches()
		if not was_portrait and main.game_started and not main.game_over and not main.paused:
			main._toggle_pause()
		was_portrait = true
		queue_redraw()
		return
	was_portrait = false
	if main.paused or main.game_over:
		reset_touches()
	else:
		main.mobile_move_vector = joystick_vector
		main.mobile_sprint = joystick_vector.y < -0.88
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_button_rects()

func _update_button_rects() -> void:
	var viewport_size: Vector2 = size
	var ui_scale: float = clampf(viewport_size.y / 720.0, 0.72, 1.25)
	pause_rect = Rect2(viewport_size.x - 90, 76, 68, 54)
	fire_rect = Rect2(viewport_size.x - 170.0 * ui_scale, viewport_size.y - 185.0 * ui_scale, 120.0 * ui_scale, 120.0 * ui_scale)
	reload_rect = Rect2(viewport_size.x - 310.0 * ui_scale, viewport_size.y - 142.0 * ui_scale, 92.0 * ui_scale, 92.0 * ui_scale)
	jump_rect = Rect2(viewport_size.x - 304.0 * ui_scale, viewport_size.y - 260.0 * ui_scale, 82.0 * ui_scale, 82.0 * ui_scale)
	weapon_rect = Rect2(viewport_size.x - 420.0 * ui_scale, viewport_size.y - 160.0 * ui_scale, 82.0 * ui_scale, 82.0 * ui_scale)
	sprint_rect = Rect2(22.0 * ui_scale, viewport_size.y - 275.0 * ui_scale, 88.0 * ui_scale, 70.0 * ui_scale)
	aim_rect = Rect2(viewport_size.x - 168.0 * ui_scale, viewport_size.y - 302.0 * ui_scale, 100.0 * ui_scale, 72.0 * ui_scale)

func reset_touches() -> void:
	left_touch_id = -1
	right_touch_id = -1
	fire_touch_id = -1
	joystick_vector = Vector2.ZERO
	if main == null: return
	main.mobile_move_vector = Vector2.ZERO
	main.mobile_look_delta = Vector2.ZERO
	main.mobile_fire = false
	main.mobile_sprint = false
	main.mobile_aim = false
	main.mobile_jump = false
	main.mobile_reload = false
	main.mobile_weapon = false

func _input(event: InputEvent) -> void:
	if not visible or main == null or _is_portrait(): return
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag): return
	get_viewport().set_input_as_handled()
	_update_button_rects()
	if event is InputEventScreenTouch:
		if event.pressed:
			if main.upgrade_pending:
				main.select_upgrade(clampi(int(event.position.x / (size.x / 3.0)), 0, 2))
				return
			if not main.game_started or main.game_over:
				reset_touches()
				main._start_game()
				return
			if pause_rect.has_point(event.position) or main.paused:
				main._toggle_pause()
				main.settings_panel.visible = false
				return
			if fire_rect.has_point(event.position) and fire_touch_id == -1:
				fire_touch_id = event.index
				main.mobile_fire = true
			elif reload_rect.has_point(event.position): main.mobile_reload = true
			elif jump_rect.has_point(event.position): main.mobile_jump = true
			elif weapon_rect.has_point(event.position): main.mobile_weapon = true
			elif aim_rect.has_point(event.position): main.mobile_aim = not main.mobile_aim
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
				main.mobile_move_vector = Vector2.ZERO
				main.mobile_sprint = false
			if event.index == right_touch_id: right_touch_id = -1
	elif not main.paused and event is InputEventScreenDrag:
		if event.index == left_touch_id:
			joystick_vector = (event.position - joystick_origin).limit_length(JOYSTICK_RADIUS) / JOYSTICK_RADIUS
		elif event.index == right_touch_id or event.index == fire_touch_id:
			main.mobile_look_delta += event.relative

func _draw() -> void:
	if not visible:
		return
	if _is_portrait():
		draw_rect(Rect2(Vector2.ZERO, size), Color("#010301"), true)
		var center := size * 0.5
		draw_arc(center, 130.0, 0, TAU, 40, GREEN, 6.0)
		draw_line(center + Vector2(-65, 0), center + Vector2(65, 0), GREEN, 6.0)
		draw_string(FONT, center + Vector2(-300, 220), "ROTATE TO LANDSCAPE", HORIZONTAL_ALIGNMENT_CENTER, 600, 48, GREEN)
		return
	if not main.game_started or main.game_over or main.paused: return
	_update_button_rects()
	_draw_button(pause_rect, "II", false)
	var center := joystick_origin if left_touch_id != -1 else Vector2(125, size.y - 125)
	draw_circle(center, JOYSTICK_RADIUS, Color(0.05, 0.3, 0.08, 0.22))
	draw_arc(center, JOYSTICK_RADIUS, 0, TAU, 48, GREEN, 3.0)
	var knob := center + joystick_vector * 48.0
	draw_circle(knob, 30.0, Color(0.49, 1.0, 0.22, 0.42))
	draw_arc(knob, 30.0, 0, TAU, 32, GREEN, 2.0)
	draw_circle(fire_rect.get_center(), fire_rect.size.x * 0.5, Color(0.005, 0.04, 0.005, 0.9))
	draw_arc(fire_rect.get_center(), fire_rect.size.x * 0.5, 0, TAU, 40, GREEN, 3.0)
	draw_string(FONT, fire_rect.get_center() + Vector2(-28, 7), "FIRE", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, GREEN)
	draw_circle(reload_rect.get_center(), reload_rect.size.x * 0.5, Color(0.005, 0.04, 0.005, 0.9))
	draw_arc(reload_rect.get_center(), reload_rect.size.x * 0.5, 0, TAU, 32, GREEN, 2.0)
	draw_string(FONT, reload_rect.get_center() + Vector2(-32, 6), "RELOAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, GREEN)
	_draw_button(jump_rect, "JUMP", main.mobile_jump)
	_draw_button(weapon_rect, "SWAP", main.mobile_weapon)
	draw_string(FONT, center + Vector2(-70, -105), "PUSH UP TO SPRINT", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GREEN)
	_draw_button(aim_rect, "AIM", main.mobile_aim)
	if main.mobile_auto_fire:
		draw_string(FONT, Vector2(size.x - 340, 175), "AUTO-FIRE ON", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#164d20"))

func _draw_button(rect: Rect2, label: String, active: bool) -> void:
	draw_rect(rect, Color(0.005, 0.04, 0.005, 0.88), true)
	var color := Color(0.49, 1.0, 0.22, 1.0 if active else 0.75)
	draw_rect(rect, color, false, 3.0 if active else 1.5)
	draw_string(FONT, rect.position + Vector2(8, rect.size.y * 0.6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, GREEN)
