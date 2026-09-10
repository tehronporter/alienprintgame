extends Control

const GREEN := Color("#7dff35")
const HOT := Color("#c4ff82")
const DIM := Color("#164d20")

var main: Node
var hit_timer := 0.0
var damage_timer := 0.0
var elite_timer := 0.0
var pulse := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	hit_timer = max(0.0, hit_timer - delta)
	damage_timer = max(0.0, damage_timer - delta)
	elite_timer = max(0.0, elite_timer - delta)
	queue_redraw()

func show_hit() -> void:
	hit_timer = 0.14

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
	_draw_health(Vector2(28, view.y - 82), float(main.player.health) / 100.0)
	_draw_ammo(Vector2(view.x - 255, view.y - 86), main.player.ammo, 24)
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

func _draw_crosshair(center: Vector2) -> void:
	if not main.game_started or main.game_over or main.paused:
		return
	var gap := 9.0 if hit_timer <= 0.0 else 14.0
	var length := 8.0
	var color := HOT if hit_timer > 0.0 else GREEN
	draw_line(center + Vector2(-gap - length, 0), center + Vector2(-gap, 0), color, 2.0)
	draw_line(center + Vector2(gap, 0), center + Vector2(gap + length, 0), color, 2.0)
	draw_line(center + Vector2(0, -gap - length), center + Vector2(0, -gap), color, 2.0)
	draw_line(center + Vector2(0, gap), center + Vector2(0, gap + length), color, 2.0)
	if hit_timer > 0.0:
		draw_line(center + Vector2(-7, -7), center + Vector2(7, 7), HOT, 3.0)
		draw_line(center + Vector2(7, -7), center + Vector2(-7, 7), HOT, 3.0)

func _draw_health(pos: Vector2, ratio: float) -> void:
	draw_string(ThemeDB.fallback_font, pos + Vector2(0, -12), "VITALS", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GREEN)
	for i in range(10):
		var segment := Rect2(pos + Vector2(float(i) * 18.0, 0), Vector2(13, 24))
		draw_rect(segment, GREEN if float(i) < ratio * 10.0 else DIM, false, 2.0)
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
