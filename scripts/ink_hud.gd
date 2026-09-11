extends Control

const GREEN := Color("#7dff35")
const HOT := Color("#c4ff82")
const DIM := Color("#164d20")

var main: Node
var hit_timer := 0.0
var damage_timer := 0.0
var elite_timer := 0.0
var pulse := 0.0
var critical_timer := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	hit_timer = max(0.0, hit_timer - delta)
	damage_timer = max(0.0, damage_timer - delta)
	elite_timer = max(0.0, elite_timer - delta)
	critical_timer = max(0.0, critical_timer - delta)
	queue_redraw()

func show_hit(critical := false) -> void:
	hit_timer = 0.14
	if critical:
		critical_timer = 0.35

func show_damage() -> void:
	damage_timer = 0.32

func show_elite() -> void:
	elite_timer = 4.0

func _draw() -> void:
	if main == null:
		return
	var view := size
	var center := view * 0.5
	_draw_corner_frame(view)
	_draw_crosshair(center)
	if not main.game_started or main.game_over:
		return
	_draw_compass(Vector2(center.x, 112.0), view.x)
	if view.x >= 760.0:
		_draw_radar(Vector2(92, 122), 48.0)
	_draw_meter(Vector2(28, view.y - 82), float(main.player.health) / float(main.player.max_health), "VITALS", GREEN)
	_draw_meter(Vector2(28, view.y - 124), float(main.player.shield) / 100.0, "SHIELD", HOT)
	_draw_ammo(Vector2(view.x - 255, view.y - 86), main.player.ammo, main.player.get_mag_size())
	_draw_weapon_slots(Vector2(center.x - 145, view.y - 142))
	if critical_timer > 0.0:
		draw_string(ThemeDB.fallback_font, center + Vector2(-58, -36), "WEAK POINT", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, HOT)
	if elite_timer > 0.0:
		var alpha := 0.55 + sin(pulse * 9.0) * 0.35
		var warning := Color(HOT.r, HOT.g, HOT.b, alpha)
		draw_line(Vector2(center.x - 210, 82), Vector2(center.x + 210, 82), warning, 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(center.x - 103, 72), "ELITE SIGNAL DETECTED", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, warning)
	if damage_timer > 0.0:
		var strength := damage_timer / 0.32
		var damage_color := Color(0.18, 1.0, 0.22, strength * 0.28)
		for inset in range(4):
			draw_rect(Rect2(Vector2(inset * 8, inset * 8), view - Vector2(inset * 16, inset * 16)), damage_color, false, 5.0)

func _draw_corner_frame(view: Vector2) -> void:
	var inset := 16.0
	var span: float = minf(80.0, view.x * 0.08)
	for corner in [Vector2(inset, inset), Vector2(view.x - inset, inset), Vector2(inset, view.y - inset), Vector2(view.x - inset, view.y - inset)]:
		var sx := 1.0 if corner.x < view.x * 0.5 else -1.0
		var sy := 1.0 if corner.y < view.y * 0.5 else -1.0
		draw_line(corner, corner + Vector2(sx * span, 0), DIM, 2.0)
		draw_line(corner, corner + Vector2(0, sy * span), DIM, 2.0)
	# Deliberately mismatched second pass keeps the frame from feeling machine-perfect.
	draw_line(Vector2(24, 20), Vector2(minf(128.0, view.x * 0.13), 23), GREEN, 1.0)
	draw_line(Vector2(view.x - 25, view.y - 20), Vector2(view.x - minf(118.0, view.x * 0.12), view.y - 24), GREEN, 1.0)

func _draw_compass(pos: Vector2, view_width: float) -> void:
	var span: float = minf(310.0, view_width * 0.38)
	draw_line(pos - Vector2(span * 0.5, 0), pos + Vector2(span * 0.5, 0), DIM, 1.5)
	var heading: float = fposmod(rad_to_deg(main.player.yaw), 360.0)
	for tick in range(-4, 5):
		var x: float = pos.x + float(tick) * span / 8.0
		var height: float = 10.0 if tick == 0 else 5.0
		draw_line(Vector2(x, pos.y - height), Vector2(x + float(tick % 2), pos.y + height), GREEN if tick == 0 else DIM, 2.0)
	var cardinal := "N"
	if heading >= 45.0 and heading < 135.0:
		cardinal = "W"
	elif heading >= 135.0 and heading < 225.0:
		cardinal = "S"
	elif heading >= 225.0 and heading < 315.0:
		cardinal = "E"
	draw_string(ThemeDB.fallback_font, pos + Vector2(-12, -15), cardinal + "  %03d" % int(heading), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GREEN)

func _draw_radar(pos: Vector2, radius: float) -> void:
	draw_arc(pos, radius, 0.0, TAU, 32, DIM, 2.0)
	draw_arc(pos + Vector2(1, -1), radius - 5.0, 0.0, TAU, 28, GREEN, 1.0)
	draw_line(pos - Vector2(radius, 0), pos + Vector2(radius, 0), DIM, 1.0)
	draw_line(pos - Vector2(0, radius), pos + Vector2(0, radius), DIM, 1.0)
	var forward := Vector2(0, -1).rotated(-main.player.yaw)
	draw_colored_polygon(PackedVector2Array([pos + forward * 11.0, pos + forward.rotated(2.35) * 7.0, pos + forward.rotated(-2.35) * 7.0]), GREEN)
	var drawn := 0
	for enemy in main.enemy_pool:
		if not enemy.active:
			continue
		var offset_3d: Vector3 = enemy.global_position - main.player.global_position
		var offset := Vector2(offset_3d.x, offset_3d.z).rotated(main.player.yaw) * (radius / 34.0)
		if offset.length() < radius - 4.0:
			draw_circle(pos + offset, 2.5 if enemy.enemy_type != "elite" else 4.5, HOT if enemy.enemy_type == "elite" else GREEN)
			drawn += 1
			if drawn >= 16:
				break
	draw_string(ThemeDB.fallback_font, pos + Vector2(-30, radius + 17), "MALL RADAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, DIM)

func _draw_crosshair(center: Vector2) -> void:
	if not main.game_started or main.game_over or main.paused:
		return
	var gap := 5.0 if main.player.is_aiming else 16.0 if main.player.is_sprinting else 9.0 if hit_timer <= 0.0 else 14.0
	var length := 8.0
	var color := HOT if hit_timer > 0.0 else GREEN
	draw_line(center + Vector2(-gap - length, 0), center + Vector2(-gap, 0), color, 2.0)
	draw_line(center + Vector2(gap, 0), center + Vector2(gap + length, 0), color, 2.0)
	draw_line(center + Vector2(0, -gap - length), center + Vector2(0, -gap), color, 2.0)
	draw_line(center + Vector2(0, gap), center + Vector2(0, gap + length), color, 2.0)
	if hit_timer > 0.0:
		draw_line(center + Vector2(-7, -7), center + Vector2(7, 7), HOT, 3.0)
		draw_line(center + Vector2(7, -7), center + Vector2(-7, 7), HOT, 3.0)

func _draw_meter(pos: Vector2, ratio: float, label: String, active_color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos + Vector2(0, -12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, active_color)
	for i in range(10):
		var segment := Rect2(pos + Vector2(float(i) * 18.0, 0), Vector2(13, 24))
		draw_rect(segment, active_color if float(i) < ratio * 10.0 else DIM, false, 2.0)
		if float(i) < ratio * 10.0:
			draw_line(segment.position + Vector2(3, 19), segment.position + Vector2(10, 5), Color(0.25, 0.72, 0.18, 0.7), 2.0)

func _draw_ammo(pos: Vector2, ammo: int, capacity: int) -> void:
	draw_string(ThemeDB.fallback_font, pos + Vector2(0, -10), "INK CELLS", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GREEN)
	for i in range(capacity):
		var row := i / 12
		var col := i % 12
		var x := pos.x + float(col) * 18.0
		var y := pos.y + float(row) * 20.0
		var color := HOT if i < ammo else DIM
		draw_line(Vector2(x, y), Vector2(x + 10, y - 10), color, 3.0)
		draw_line(Vector2(x + 3, y + 2), Vector2(x + 12, y - 7), color, 1.0)

func _draw_weapon_slots(pos: Vector2) -> void:
	for index in range(3):
		var slot := Rect2(pos + Vector2(float(index) * 98.0, 0), Vector2(88, 42))
		var selected: bool = index == main.player.current_weapon
		draw_rect(slot, HOT if selected else DIM, false, 3.0 if selected else 1.5)
		draw_string(ThemeDB.fallback_font, slot.position + Vector2(7, 17), str(index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, HOT if selected else GREEN)
		var short_name := "RIFLE" if index == 0 else "SCATTER" if index == 1 else "PISTOL"
		draw_string(ThemeDB.fallback_font, slot.position + Vector2(22, 29), short_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, HOT if selected else DIM)
