extends Control

const FONT = preload("res://assets/fonts/Kalam-Regular.ttf")
const GREEN := Color("#99ff60")
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
	_draw_radar(Vector2(72, 113), 33.0)
	_draw_meter(Vector2(58, view.y - 76), float(main.player.health) / float(main.player.max_health), "HEALTH", GREEN)
	_draw_meter(Vector2(58, view.y - 122), float(main.player.shield) / 100.0, "SHIELD", HOT)
	_draw_ammo(Vector2(view.x - 222, view.y - 70), main.player.ammo, main.player.get_mag_size())
	_draw_weapon_slots(Vector2(center.x - 130, view.y - 78))
	if critical_timer > 0.0:
		draw_string(FONT, center + Vector2(-58, -36), "WEAK POINT", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, HOT)
	if elite_timer > 0.0:
		var alpha := 0.55 + sin(pulse * 9.0) * 0.35
		var warning := Color(HOT.r, HOT.g, HOT.b, alpha)
		draw_line(Vector2(center.x - 210, 82), Vector2(center.x + 210, 82), warning, 3.0)
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
	draw_string(FONT, pos + Vector2(-12, -15), cardinal + "  %03d" % int(heading), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GREEN)

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
	draw_string(FONT, pos + Vector2(-30, radius + 17), "MALL RADAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, DIM)

func _draw_crosshair(center: Vector2) -> void:
	if not main.game_started or main.game_over or main.paused:
		return
	draw_arc(center, 15 if not main.player.is_aiming else 7, 0.1, TAU - 0.12, 28, GREEN, 1.5, true)
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
	draw_style_box(_panel(), Rect2(pos - Vector2(14, 20), Vector2(216, 47)))
	draw_string(FONT, pos + Vector2(0, -5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, active_color)
	var corners := PackedVector2Array([pos, pos + Vector2(181, -1), pos + Vector2(183, 22), pos + Vector2(-1, 24), pos])
	draw_polyline(corners, active_color, 2.5, true)
	for i in range(int(ratio * 35)):
		var x := 4 + i * 5.0
		draw_line(pos + Vector2(x, 19), pos + Vector2(x + 8, 4), active_color, 2, true)
	if label == "HEALTH":
		var heart := PackedVector2Array([Vector2(-22, 20), Vector2(-35, 7), Vector2(-35, 0), Vector2(-30, -4), Vector2(-23, 0), Vector2(-17, -4), Vector2(-10, 0), Vector2(-10, 7), Vector2(-22, 20)])
		for i in range(heart.size()): heart[i] += pos
		draw_polyline(heart, GREEN, 2.5, true)

func _panel() -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.0, 0.012, 0.0, 0.82)
	return panel

func _draw_ammo(pos: Vector2, ammo: int, _capacity: int) -> void:
	draw_style_box(_panel(), Rect2(pos - Vector2(14, 32), Vector2(214, 73)))
	var text := "RELOADING" if main.player.reloading else "%02d / %03d" % [ammo, main.player.reserve_ammo]
	draw_string(FONT, pos + Vector2(22, 14), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 32 if not main.player.reloading else 22, HOT)
	draw_string(FONT, pos + Vector2(22, -23), main.player.get_weapon_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, GREEN)
	draw_line(pos + Vector2(12, 25), pos + Vector2(181, 22), GREEN, 2.5, true)
	for i in range(3):
		var p := pos + Vector2(-16 + i * 10, 12)
		draw_polyline(PackedVector2Array([p, p + Vector2(0, -18), p + Vector2(3, -26), p + Vector2(6, -18), p + Vector2(6, 0), p]), GREEN, 1.6, true)

func _draw_weapon_slots(pos: Vector2) -> void:
	for index in range(3):
		var slot := Rect2(pos + Vector2(float(index) * 89.0, 0), Vector2(80, 35))
		var selected: bool = index == main.player.current_weapon
		draw_style_box(_panel(), slot)
		var outline := PackedVector2Array([slot.position, slot.position + Vector2(80, -1), slot.end, slot.position + Vector2(-1, 35), slot.position])
		draw_polyline(outline, HOT if selected else DIM, 2 if selected else 1.0, true)
		var short_name := "RIFLE" if index == 0 else "SCATTER" if index == 1 else "PISTOL"
		draw_string(FONT, slot.position + Vector2(7, 24), str(index + 1) + " " + short_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, HOT if selected else GREEN)
