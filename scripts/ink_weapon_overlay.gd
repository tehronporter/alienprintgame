extends Control
## Calibrated barrel axes project toward the actual shooting reticle.
const Art = preload("res://scripts/ink_art.gd")
# Muzzle and a second point along the barrel, normalized within each atlas region.
const BARRELS := [
	[Vector2(0.235, 0.18), Vector2(0.72, 0.57)],
	[Vector2(0.195, 0.19), Vector2(0.70, 0.50)],
	[Vector2(0.325, 0.18), Vector2(0.64, 0.38)]
]
var player: Node
var weapons: Array[AtlasTexture] = []
var aim_blend := 0.0
var reload_blend := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for kind in ["rifle", "scatter", "pistol"]: weapons.append(Art.texture(kind))

func _process(delta: float) -> void:
	if player != null:
		aim_blend = move_toward(aim_blend, 1.0 if player.is_aiming else 0.0, delta * 7)
		reload_blend = move_toward(reload_blend, 1.0 if player.reloading else 0.0, delta * 7)
	queue_redraw()

func _draw() -> void:
	if player == null or not player.main.game_started or player.main.game_over:
		return
	var index: int = player.current_weapon
	var texture := weapons[index]
	var h := size.y * (0.53 if index != 2 else 0.48)
	var extent := Vector2(h * texture.get_width() / texture.get_height(), h)
	var moving: bool = Vector2(player.velocity.x, player.velocity.z).length() > 0.5
	var bob := Vector2(sin(player.bob_time) * 3, absf(cos(player.bob_time)) * 3) if moving else Vector2.ZERO
	var muzzle := size * Vector2(lerpf(0.64, 0.54, aim_blend), lerpf(0.63, 0.57, aim_blend))
	muzzle += bob + Vector2(player.recoil * 4, player.recoil * 10 + reload_blend * h * 0.7)
	var source_tip: Vector2 = BARRELS[index][0] * extent
	var source_axis: Vector2 = (BARRELS[index][0] - BARRELS[index][1]) * extent
	var target_axis := size * 0.5 - muzzle
	var angle := target_axis.angle() - source_axis.angle()
	angle += reload_blend * 0.35
	draw_set_transform(muzzle, angle)
	draw_texture_rect(texture, Rect2(-source_tip, extent), false, Color(1.3, 1.6, 1.5))
	draw_set_transform(Vector2.ZERO)
	var flash = player.weapon_flashes[index]
	if flash.visible and not player.reloading:
		for i in range(7):
			var direction := Vector2.from_angle(TAU * i / 7)
			draw_line(muzzle + direction * 9, muzzle + direction * (24 + i % 3 * 8), Color("#c4ff82"), 2.0, true)
