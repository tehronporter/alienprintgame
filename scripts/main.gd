extends Node3D

const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const SpawnDirector = preload("res://scripts/spawn_director.gd")
const MobileControls = preload("res://scripts/mobile_controls.gd")
const InkHUD = preload("res://scripts/ink_hud.gd")
const EnemyProjectile = preload("res://scripts/enemy_projectile.gd")
const Pickup = preload("res://scripts/pickup.gd")
const AudioManager = preload("res://scripts/audio_manager.gd")

const GREEN := Color("#7dff35")
const GREEN_SOFT := Color("#164d20")
const GREEN_DARK := Color("#041108")
const BLACK := Color("#010301")
const POOL_SIZE := 48

var player: CharacterBody3D
var director: Node
var enemy_pool: Array[Node] = []
var score := 0
var high_score := 0
var kills := 0
var shots := 0
var hits := 0
var game_started := false
var game_over := false
var paused := false
var survival_time := 0.0
var hud: CanvasLayer
var hud_labels := {}
var crosshair: Label
var arena_root: Node3D
var settings_panel: PanelContainer
var sensitivity_slider: HSlider
var sensitivity_value: Label
var touchpad_toggle: CheckButton
var look_sensitivity := 0.0025
var touchpad_mode := false
var mobile_controls_visible := false
var mobile_move_vector := Vector2.ZERO
var mobile_look_delta := Vector2.ZERO
var mobile_fire := false
var mobile_reload := false
var mobile_jump := false
var mobile_sprint := false
var mobile_aim := false
var mobile_weapon := false
var mobile_auto_fire := true
var ink_hud: Control
var streak := 0
var streak_timer := 0.0
var projectile_pool: Array[Node] = []
var pickup_pool: Array[Node] = []
var audio_manager: Node
var upgrade_pending := false
var upgrade_choices: Array[String] = []
var next_upgrade_time := 120.0
var best_survival := 0.0
var auto_fire_toggle: CheckButton
var reduced_motion := false
var reduced_motion_toggle: CheckButton
var material_cache: Dictionary = {}
var tension_timer := 3.0
const SETTINGS_PATH := "user://neon_mall_settings.cfg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_load_settings()
	_build_world()
	_build_player()
	_build_enemy_pool()
	_build_runtime_pools()
	_build_hud()
	_show_title()

func _process(delta: float) -> void:
	if mobile_fire and not game_started:
		mobile_fire = false
		_start_game()
	elif mobile_fire and game_over:
		mobile_fire = false
		_restart_game()
	if not game_started or game_over or paused:
		return
	survival_time += delta
	tension_timer -= delta
	if tension_timer <= 0.0:
		var threat_tier := int(survival_time / 60.0) + 1
		play_sound("tension", 0.92 + float(threat_tier) * 0.035)
		tension_timer = maxf(1.4, 4.6 - float(threat_tier) * 0.38)
	if survival_time >= next_upgrade_time and not upgrade_pending:
		_show_upgrade_choice()
	if streak_timer > 0.0:
		streak_timer -= delta
		if streak_timer <= 0.0:
			streak = 0
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if upgrade_pending and event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			select_upgrade(0)
		elif event.keycode == KEY_2:
			select_upgrade(1)
		elif event.keycode == KEY_3:
			select_upgrade(2)
		return
	if event.is_action_pressed("pause") and game_started and not game_over:
		_toggle_pause()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER and not game_started:
		_start_game()
	if event.is_action_pressed("fire") and game_started and game_over:
		_restart_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and game_started and not game_over and not paused:
		_toggle_pause()

func _build_world() -> void:
	arena_root = Node3D.new()
	arena_root.name = "NationalMall"
	add_child(arena_root)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = BLACK
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#06320b")
	environment.ambient_light_energy = 0.28
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = environment
	add_child(env)
	_make_box("MallGround", Vector3(0, -0.6, 0), Vector3(110, 1, 110), GREEN_DARK, 0.03)
	_make_box("ReflectingPool", Vector3(0, -0.03, -5), Vector3(8, 0.12, 82), Color("#020804"), 0.24)
	_make_outline_box(Vector3(0, 0.06, -5), Vector3(8.4, 0.2, 82), GREEN, 1.7)
	_make_capitol(Vector3(0, 0, -45))
	_make_washington_monument(Vector3(0, 0, 38))
	_make_path_lines()
	_make_cover()
	_make_lamps()
	_make_tree_line()
	_make_flags()
	_make_ground_doodles()
	_make_map_set_dressing()
	_make_pool_ink()
	_make_sky_scratches()
	_make_ufo(Vector3(-24, 17, -22), 1.2)
	_make_ufo(Vector3(24, 20, 4), 0.8)

func _make_material(color: Color, emission_energy := 1.0) -> StandardMaterial3D:
	var key := "%s_%.2f" % [color.to_html(), emission_energy]
	if material_cache.has(key):
		return material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = emission_energy
	material.roughness = 1.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_cache[key] = material
	return material

func _make_box(label: String, pos: Vector3, size: Vector3, color: Color, energy := 1.0) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.position = pos
	mesh_node.material_override = _make_material(color, energy)
	arena_root.add_child(mesh_node)
	var body := StaticBody3D.new()
	body.position = pos
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	arena_root.add_child(body)
	return mesh_node

func _make_visual_box(label: String, pos: Vector3, size: Vector3, color: Color, energy := 1.0) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.position = pos
	mesh_node.material_override = _make_material(color, energy)
	arena_root.add_child(mesh_node)
	return mesh_node

func _make_visual_sphere(label: String, pos: Vector3, radius: float, squash: Vector3, color: Color, energy := 1.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	node.mesh = mesh
	node.position = pos
	node.scale = squash
	node.material_override = _make_material(color, energy)
	arena_root.add_child(node)
	return node

func _make_stroke(label: String, from: Vector3, to: Vector3, width: float, color: Color, energy := 1.0) -> MeshInstance3D:
	var midpoint := (from + to) * 0.5
	var stroke := _make_visual_box(label, midpoint, Vector3(width, width, from.distance_to(to)), color, energy)
	stroke.look_at(to, Vector3.UP)
	return stroke

func _make_outline_box(pos: Vector3, size: Vector3, color: Color, energy := 1.0) -> void:
	var t := 0.08
	_make_visual_box("InkTop", pos + Vector3(0, size.y * 0.5, 0), Vector3(size.x, t, t), color, energy)
	_make_visual_box("InkBottom", pos - Vector3(0, size.y * 0.5, 0), Vector3(size.x, t, t), color, energy)
	_make_visual_box("InkLeft", pos + Vector3(-size.x * 0.5, 0, 0), Vector3(t, size.y, t), color, energy)
	_make_visual_box("InkRight", pos + Vector3(size.x * 0.5, 0, 0), Vector3(t, size.y, t), color, energy)
	_make_visual_box("InkFrontTop", pos + Vector3(0, size.y * 0.5, -size.z * 0.5), Vector3(size.x, t, t), color, energy)
	_make_visual_box("InkBackTop", pos + Vector3(0, size.y * 0.5, size.z * 0.5), Vector3(size.x, t, t), color, energy)
	_make_visual_box("InkFrontBottom", pos - Vector3(0, size.y * 0.5, size.z * 0.5), Vector3(size.x, t, t), color, energy)
	_make_visual_box("InkBackBottom", pos - Vector3(0, size.y * 0.5, -size.z * 0.5), Vector3(size.x, t, t), color, energy)
	for x in [-size.x * 0.5, size.x * 0.5]:
		for z in [-size.z * 0.5, size.z * 0.5]:
			_make_visual_box("InkCorner", pos + Vector3(x, 0, z), Vector3(t, size.y, t), color, energy)

func _make_landmark(label: String, pos: Vector3, size: Vector3, columns: int) -> void:
	_make_box(label + "Core", pos, size, GREEN_DARK, 0.08)
	_make_outline_box(pos, size, GREEN, 1.15)
	var line_color := GREEN
	for i in range(columns):
		var x: float = pos.x - size.x * 0.42 + (float(i) / float(max(1, columns - 1))) * size.x * 0.84
		_make_box(label + "Column" + str(i), Vector3(x, pos.y + size.y * 0.12, pos.z - size.z * 0.55), Vector3(0.38, size.y * 0.72, 0.28), line_color, 1.8)
	_make_box(label + "TopLine", Vector3(pos.x, pos.y + size.y * 0.52, pos.z - size.z * 0.58), Vector3(size.x * 1.08, 0.32, 0.32), line_color, 2.0)
	_make_box(label + "Step", Vector3(pos.x, 0.25, pos.z + size.z * 0.25), Vector3(size.x * 1.4, 0.35, size.z * 0.8), GREEN_SOFT, 0.2)

func _make_capitol(pos: Vector3) -> void:
	_make_box("CapitolBody", pos + Vector3(0, 3.0, 0), Vector3(22, 6, 7), GREEN_DARK, 0.08)
	_make_outline_box(pos + Vector3(0, 3.0, 0), Vector3(22, 6, 7), GREEN, 1.4)
	for i in range(15):
		var x: float = -9.0 + float(i) * 1.28
		_make_visual_box("CapitolColumn", pos + Vector3(x, 3.9, -3.8), Vector3(0.32, 4.8, 0.22), GREEN, 1.8)
	_make_visual_box("CapitolSteps", pos + Vector3(0, 0.35, -4.4), Vector3(27, 0.35, 2.4), GREEN, 1.7)
	_make_visual_box("CapitolDomeBase", pos + Vector3(0, 7.1, 0), Vector3(10, 0.42, 4.2), GREEN, 1.8)
	var dome := MeshInstance3D.new()
	var dome_mesh := SphereMesh.new()
	dome_mesh.radius = 5.0
	dome_mesh.height = 4.5
	dome.mesh = dome_mesh
	dome.scale = Vector3(1.0, 0.48, 0.65)
	dome.position = pos + Vector3(0, 8.3, 0)
	dome.material_override = _make_material(GREEN_DARK, 0.08)
	arena_root.add_child(dome)
	_make_outline_box(pos + Vector3(0, 8.25, 0), Vector3(10.4, 0.18, 4.5), GREEN, 1.8)
	_make_visual_box("CapitolSpire", pos + Vector3(0, 11.3, 0), Vector3(0.28, 4.0, 0.28), GREEN, 2.0)
	# Wings, windows, dome ribs, and uneven roof strokes are the landmark's visual signature.
	for side in [-1.0, 1.0]:
		_make_outline_box(pos + Vector3(side * 14.0, 2.65, 0.5), Vector3(6.0, 5.3, 6.0), GREEN, 1.2)
		_make_visual_box("CapitolWingRoof", pos + Vector3(side * 14.0, 5.55, -0.2), Vector3(7.0, 0.18, 6.8), GREEN, 1.6).rotation.z = side * 0.018
		for window in range(4):
			_make_outline_box(pos + Vector3(side * (11.7 + float(window) * 1.45), 3.0, -2.65), Vector3(0.65, 1.25, 0.1), GREEN_SOFT, 0.9)
	for rib in range(7):
		var x := -4.3 + float(rib) * 1.43
		_make_stroke("DomeRib", pos + Vector3(x, 7.15, -2.2), pos + Vector3(x * 0.25, 10.25, -1.15), 0.09, GREEN, 1.7)
	for step in range(5):
		_make_visual_box("CapitolStair", pos + Vector3(0, 0.12 + float(step) * 0.12, -5.6 + float(step) * 0.35), Vector3(29.0 - float(step) * 1.6, 0.08, 0.18), GREEN, 1.35)

func _make_washington_monument(pos: Vector3) -> void:
	var shaft := MeshInstance3D.new()
	shaft.name = "WashingtonMonumentShaft"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.72
	mesh.bottom_radius = 2.1
	mesh.height = 24.0
	mesh.radial_segments = 4
	shaft.mesh = mesh
	shaft.position = pos + Vector3(0, 12.2, 0)
	shaft.rotation.y = PI * 0.25
	shaft.material_override = _make_material(GREEN_DARK, 0.08)
	arena_root.add_child(shaft)
	for side in [-1.0, 1.0]:
		_make_stroke("MonumentEdge", pos + Vector3(side * 2.1, 0.2, -0.1), pos + Vector3(side * 0.7, 24.3, -0.1), 0.14, GREEN, 2.0)
		_make_stroke("MonumentEdgeBack", pos + Vector3(0.0, 0.2, side * 2.1), pos + Vector3(0.0, 24.3, side * 0.7), 0.11, GREEN_SOFT, 1.2)
	for tier in range(8):
		var y: float = 2.0 + float(tier) * 2.75
		var half_width: float = lerpf(2.0, 0.78, y / 24.0)
		_make_visual_box("MonumentCourse", pos + Vector3(0, y, -half_width), Vector3(half_width * 1.9, 0.06, 0.06), GREEN_SOFT, 0.9)
	_make_stroke("MonumentPointA", pos + Vector3(-0.7, 24.2, 0), pos + Vector3(0, 27.0, 0), 0.13, GREEN, 2.2)
	_make_stroke("MonumentPointB", pos + Vector3(0.7, 24.2, 0), pos + Vector3(0, 27.0, 0), 0.13, GREEN, 2.2)
	for i in range(18):
		var angle := float(i) / 18.0 * TAU
		var radius := 6.2
		_make_visual_box("MonumentFlagPole", pos + Vector3(cos(angle) * radius, 1.6, sin(angle) * radius), Vector3(0.06, 3.2, 0.06), GREEN_SOFT, 0.9)

func _make_path_lines() -> void:
	for x in [-18.0, -9.0, 9.0, 18.0]:
		_make_visual_box("MallPath", Vector3(x, 0.02, 0), Vector3(0.12, 0.04, 92), GREEN, 1.25)
	for z in [-28.0, -12.0, 12.0, 28.0]:
		_make_visual_box("CrossPath", Vector3(0, 0.03, z), Vector3(72, 0.04, 0.12), GREEN, 1.25)

func _make_cover() -> void:
	for i in range(18):
		var angle := float(i) * 2.399
		var radius := 15.0 + fmod(float(i * 13), 25.0)
		var pos := Vector3(cos(angle) * radius, 1.0, sin(angle) * radius)
		var wreckage := _make_box("Wreckage", pos, Vector3(2.8, 1.8, 1.5), GREEN_DARK, 0.12)
		wreckage.rotation.y = angle
		_make_outline_box(pos, Vector3(2.9, 1.9, 1.6), GREEN_SOFT, 0.8)

func _make_lamps() -> void:
	for x in [-31.0, -24.0, 24.0, 31.0]:
		for z in [-36.0, -18.0, 18.0, 36.0]:
			_make_box("LampPost", Vector3(x, 3.0, z), Vector3(0.18, 6.0, 0.18), GREEN, 1.8)
			_make_box("LampHead", Vector3(x, 6.1, z), Vector3(0.75, 0.18, 0.75), GREEN, 2.4)
			_make_visual_box("LampGlow", Vector3(x, 6.25, z), Vector3(1.0, 0.05, 1.0), GREEN, 2.8)

func _make_tree_line() -> void:
	for i in range(30):
		var side := -1.0 if i % 2 == 0 else 1.0
		var z := -42.0 + float(i % 15) * 5.8
		var x := side * (25.0 + float(i % 3) * 3.5)
		var height := 3.0 + float(i % 4) * 0.8
		_make_visual_box("TreeTrunk", Vector3(x, height * 0.5, z), Vector3(0.28, height, 0.28), GREEN_SOFT, 0.5)
		for branch in range(4):
			var branch_pos := Vector3(x + (float(branch) - 1.5) * 1.2, height + 1.1 + float(branch % 2) * 0.55, z)
			var branch_piece := _make_visual_box("TreeSketch", branch_pos, Vector3(2.8, 0.16, 0.16), GREEN, 1.0)
			branch_piece.rotation.z = (float(branch) - 1.5) * 0.18
		for clump in range(3):
			var canopy_pos := Vector3(x + (float(clump) - 1.0) * 1.7, height + 1.7 + float(clump % 2) * 0.7, z + float(clump - 1) * 0.35)
			_make_visual_sphere("TreeCanopy", canopy_pos, 1.65, Vector3(1.4, 0.85, 0.75), GREEN_DARK, 0.08)
			for scratch in range(3):
				var y_offset := -0.55 + float(scratch) * 0.55
				_make_stroke("LeafScratch", canopy_pos + Vector3(-1.25, y_offset, -0.7), canopy_pos + Vector3(1.2, y_offset + 0.24, -0.7), 0.08, GREEN_SOFT, 0.95)

func _make_flags() -> void:
	for x in [-19.0, 19.0]:
		for z in [-34.0, -18.0, -2.0, 14.0, 30.0]:
			_make_visual_box("FlagPole", Vector3(x, 3.2, z), Vector3(0.1, 6.4, 0.1), GREEN, 1.2)
			var flag := _make_visual_box("Flag", Vector3(x + (0.9 if x < 0 else -0.9), 5.8, z), Vector3(1.7, 0.8, 0.08), GREEN, 1.4)
			flag.rotation.y = 0.08 if x < 0 else -0.08

func _make_ground_doodles() -> void:
	for i in range(45):
		var x := -45.0 + fmod(float(i * 19), 90.0)
		var z := -45.0 + fmod(float(i * 31), 90.0)
		var length := 0.5 + float(i % 4) * 0.35
		var doodle := _make_visual_box("GroundInk", Vector3(x, 0.04, z), Vector3(length, 0.035, 0.06), GREEN_SOFT, 0.8)
		doodle.rotation.y = float(i % 7) * 0.37

func _make_ufo(pos: Vector3, scale_factor: float) -> void:
	var saucer := _make_visual_box("UFO", pos, Vector3(4.0, 0.18, 1.6) * scale_factor, GREEN, 1.8)
	var dome := _make_visual_box("UFODome", pos + Vector3(0, 0.38 * scale_factor, 0), Vector3(1.25, 0.35, 0.75) * scale_factor, GREEN, 1.5)
	for i in range(4):
		_make_visual_box("UFOBeam", pos + Vector3((float(i) - 1.5) * 0.45, -1.1 * scale_factor, 0), Vector3(0.06, 2.0 * scale_factor, 0.06), GREEN_SOFT, 0.9)

func _make_map_set_dressing() -> void:
	for x in [-12.0, 12.0]:
		for z in [-30.0, -14.0, 2.0, 18.0, 34.0]:
			_make_visual_box("BenchSeat", Vector3(x, 0.8, z), Vector3(2.8, 0.16, 0.55), GREEN_DARK, 0.2)
			_make_outline_box(Vector3(x, 0.8, z), Vector3(2.9, 0.85, 0.65), GREEN_SOFT, 0.9)
	for i in range(22):
		var angle := float(i) * 1.71
		var radius := 8.0 + fmod(float(i * 17), 34.0)
		var pos := Vector3(cos(angle) * radius, 0.65, sin(angle) * radius)
		_make_visual_box("TrashCan", pos, Vector3(0.6, 1.3, 0.6), GREEN_DARK, 0.18)
		_make_outline_box(pos, Vector3(0.65, 1.35, 0.65), GREEN_SOFT, 0.75)
	for z in [-22.0, 6.0, 30.0]:
		_make_visual_box("MallBarrier", Vector3(-7.0, 0.7, z), Vector3(4.0, 1.4, 0.25), GREEN_DARK, 0.16)
		_make_outline_box(Vector3(-7.0, 0.7, z), Vector3(4.1, 1.45, 0.3), GREEN, 1.0)
	_make_subway_entrance(Vector3(31.0, 0, 1.0))
	_make_hotdog_cart(Vector3(-15.0, 0, 15.0))
	_make_wrecked_car(Vector3(18.0, 0, -18.0), -0.28)
	_make_wrecked_car(Vector3(-22.0, 0, 27.0), 0.52)
	_make_zone_marker("CAPITOL APPROACH", Vector3(0, 0.04, -31.0), 1.0)
	_make_zone_marker("REFLECTING POOL", Vector3(0, 0.04, 0.0), 0.82)
	_make_zone_marker("MONUMENT LINE", Vector3(0, 0.04, 29.0), 0.72)

func _make_subway_entrance(pos: Vector3) -> void:
	_make_outline_box(pos + Vector3(0, 1.1, 0), Vector3(6.0, 2.2, 3.0), GREEN, 1.1)
	_make_visual_box("MetroSign", pos + Vector3(0, 2.6, -1.3), Vector3(1.8, 0.6, 0.14), GREEN, 1.7)
	for i in range(5):
		_make_visual_box("MetroStep", pos + Vector3(0, 0.1 + float(i) * 0.22, 0.8 - float(i) * 0.38), Vector3(3.3 - float(i) * 0.3, 0.15, 0.25), GREEN_SOFT, 0.45)

func _make_zone_marker(zone_text: String, pos: Vector3, scale_factor: float) -> void:
	var marker := _make_visual_box("ZoneMarker", pos + Vector3(0, 0.06, 0), Vector3(5.5, 0.04, 0.08) * scale_factor, GREEN_SOFT, 0.7)
	marker.rotation.y = 0.05
	var label := Label3D.new()
	label.name = "ZoneLabel"
	label.text = zone_text
	label.font_size = 42
	label.pixel_size = 0.012 * scale_factor
	label.modulate = GREEN_SOFT
	label.outline_size = 4
	label.outline_modulate = BLACK
	label.position = pos + Vector3(0, 0.075, 0.6)
	label.rotation.x = -PI * 0.5
	arena_root.add_child(label)

func _make_hotdog_cart(pos: Vector3) -> void:
	_make_outline_box(pos + Vector3(0, 1.0, 0), Vector3(3.2, 1.7, 1.7), GREEN, 1.25)
	_make_visual_box("CartCounter", pos + Vector3(0, 1.85, 0), Vector3(3.6, 0.13, 2.0), GREEN, 1.7)
	for side in [-1.0, 1.0]:
		_make_visual_sphere("CartWheel", pos + Vector3(side * 1.15, 0.45, -0.92), 0.42, Vector3(1, 1, 0.35), GREEN_DARK, 0.1)
		_make_outline_box(pos + Vector3(side * 1.15, 0.45, -0.96), Vector3(0.76, 0.76, 0.08), GREEN_SOFT, 1.0)
	_make_visual_box("CartUmbrellaPole", pos + Vector3(0, 3.0, 0), Vector3(0.1, 2.4, 0.1), GREEN, 1.4)
	for side in [-1.0, 1.0]:
		_make_stroke("CartUmbrella", pos + Vector3(0, 4.15, 0), pos + Vector3(side * 2.1, 3.55, 0), 0.1, GREEN, 1.7)

func _make_wrecked_car(pos: Vector3, angle: float) -> void:
	var body := _make_visual_box("WreckedCar", pos + Vector3(0, 0.75, 0), Vector3(4.6, 1.0, 2.1), GREEN_DARK, 0.1)
	body.rotation.y = angle
	_make_outline_box(pos + Vector3(0, 0.75, 0), Vector3(4.8, 1.15, 2.25), GREEN, 1.15)
	_make_outline_box(pos + Vector3(0.4, 1.55, 0), Vector3(2.4, 0.75, 1.85), GREEN_SOFT, 0.9)
	for side in [-1.0, 1.0]:
		for end in [-1.0, 1.0]:
			_make_visual_sphere("CarWheel", pos + Vector3(end * 1.55, 0.3, side * 1.0), 0.42, Vector3(1, 1, 0.38), GREEN_DARK, 0.08)
	_make_stroke("CrackedHood", pos + Vector3(-1.9, 1.25, -1.14), pos + Vector3(-0.7, 0.92, -1.14), 0.08, GREEN, 1.4)

func _make_pool_ink() -> void:
	for i in range(34):
		var z := -43.0 + float(i) * 2.45
		var x := -2.8 + fmod(float(i * 7), 5.6)
		var ripple := _make_visual_box("PoolRipple", Vector3(x, 0.045, z), Vector3(1.0 + float(i % 4) * 0.7, 0.025, 0.05), GREEN_SOFT, 0.75)
		ripple.rotation.y = sin(float(i) * 1.7) * 0.18

func _make_sky_scratches() -> void:
	for i in range(16):
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * (10.0 + float(i % 5) * 6.0)
		var z := -36.0 + float(i % 8) * 10.0
		_make_stroke("FallingInk", Vector3(x, 13.0 + float(i % 3) * 2.0, z), Vector3(x + side * 0.8, 15.5 + float(i % 3), z), 0.05, GREEN_SOFT, 0.7)

func _build_player() -> void:
	player = Player.new()
	player.name = "Player"
	player.main = self
	player.position = Vector3(0, 1.5, 18)
	add_child(player)

func _build_enemy_pool() -> void:
	for i in range(POOL_SIZE):
		var enemy := Enemy.new()
		enemy.name = "EnemyPool_%02d" % i
		enemy.main = self
		enemy.visible = false
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(enemy)
		enemy_pool.append(enemy)
	director = SpawnDirector.new()
	director.main = self
	add_child(director)

func _build_runtime_pools() -> void:
	for index in range(32):
		var projectile := EnemyProjectile.new()
		projectile.name = "ProjectilePool_%02d" % index
		projectile.main = self
		projectile.visible = false
		projectile.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(projectile)
		projectile_pool.append(projectile)
	for index in range(16):
		var pickup := Pickup.new()
		pickup.name = "PickupPool_%02d" % index
		pickup.main = self
		pickup.visible = false
		pickup.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(pickup)
		pickup_pool.append(pickup)
	audio_manager = AudioManager.new()
	audio_manager.name = "ProceduralAudio"
	add_child(audio_manager)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(root)
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var overlay_shader := Shader.new()
	overlay_shader.code = "shader_type canvas_item; void fragment(){ vec2 p=UV-vec2(0.5); float edge=smoothstep(0.25,0.78,length(p)); float scan=0.96+0.04*sin(UV.y*720.0); COLOR=vec4(0.0,0.06,0.015,0.12*edge)*scan; }"
	var overlay_material := ShaderMaterial.new()
	overlay_material.shader = overlay_shader
	overlay.material = overlay_material
	root.add_child(overlay)
	ink_hud = InkHUD.new()
	ink_hud.name = "InkHUD"
	ink_hud.main = self
	root.add_child(ink_hud)
	for spec in [["stats", Vector2(28, 22), 18], ["top_right", Vector2(-32, 22), 18], ["objective", Vector2(0, 24), 20], ["ammo", Vector2(-220, -70), 22], ["hint", Vector2(0, -48), 18], ["center", Vector2(0, -10), 34]]:
		var label := Label.new()
		label.name = spec[0]
		label.add_theme_color_override("font_color", GREEN)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.add_theme_font_size_override("font_size", spec[2])
		if spec[0] == "objective":
			label.set_anchors_preset(Control.PRESET_TOP_WIDE)
			label.offset_top = 54
			label.offset_bottom = 84
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		elif spec[0] == "center":
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.set_anchors_preset(Control.PRESET_CENTER)
			label.position += spec[1]
		elif spec[0] == "ammo":
			label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			label.offset_left = -360
			label.offset_right = -20
			label.offset_top = -198
			label.offset_bottom = -145
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		elif spec[0] == "top_right":
			label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			label.offset_left = -300
			label.offset_right = -20
			label.offset_top = 20
			label.offset_bottom = 60
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		elif spec[0] == "hint":
			label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.position += spec[1]
		else:
			label.position = spec[1]
		root.add_child(label)
		hud_labels[spec[0]] = label
	_build_settings_panel(root)
	var mobile_controls := MobileControls.new()
	mobile_controls.name = "MobileControls"
	mobile_controls.main = self
	root.add_child(mobile_controls)
	crosshair = hud_labels["center"]
	crosshair.text = ""

func _build_settings_panel(root: Control) -> void:
	settings_panel = PanelContainer.new()
	settings_panel.name = "ControlSettings"
	settings_panel.position = Vector2(28, 150)
	settings_panel.size = Vector2(390, 300)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.005, 0.025, 0.008, 0.94)
	panel_style.border_color = GREEN
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	settings_panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(settings_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	settings_panel.add_child(content)
	var title := Label.new()
	title.text = "CONTROL CALIBRATION"
	title.add_theme_color_override("font_color", GREEN)
	title.add_theme_font_size_override("font_size", 18)
	content.add_child(title)
	var help := Label.new()
	help.text = "Tune this once for your Mac pointer."
	help.add_theme_color_override("font_color", GREEN_SOFT)
	content.add_child(help)
	var sensitivity_row := HBoxContainer.new()
	var sensitivity_label := Label.new()
	sensitivity_label.text = "LOOK SENSITIVITY"
	sensitivity_label.custom_minimum_size.x = 170
	sensitivity_label.add_theme_color_override("font_color", GREEN)
	sensitivity_row.add_child(sensitivity_label)
	sensitivity_slider = HSlider.new()
	sensitivity_slider.min_value = 0.0008
	sensitivity_slider.max_value = 0.006
	sensitivity_slider.step = 0.0001
	sensitivity_slider.value = look_sensitivity
	sensitivity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sensitivity_slider.tooltip_text = "Lower values are steadier on a trackpad."
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	sensitivity_row.add_child(sensitivity_slider)
	content.add_child(sensitivity_row)
	sensitivity_value = Label.new()
	sensitivity_value.add_theme_color_override("font_color", GREEN_SOFT)
	content.add_child(sensitivity_value)
	touchpad_toggle = CheckButton.new()
	touchpad_toggle.text = "TOUCHPAD MODE (SLOW + SMOOTH)"
	touchpad_toggle.button_pressed = touchpad_mode
	touchpad_toggle.add_theme_color_override("font_color", GREEN)
	touchpad_toggle.toggled.connect(_on_touchpad_toggled)
	content.add_child(touchpad_toggle)
	auto_fire_toggle = CheckButton.new()
	auto_fire_toggle.text = "MOBILE AUTO-FIRE"
	auto_fire_toggle.button_pressed = mobile_auto_fire
	auto_fire_toggle.add_theme_color_override("font_color", GREEN)
	auto_fire_toggle.toggled.connect(_on_auto_fire_toggled)
	content.add_child(auto_fire_toggle)
	reduced_motion_toggle = CheckButton.new()
	reduced_motion_toggle.text = "REDUCED CAMERA SHAKE"
	reduced_motion_toggle.button_pressed = reduced_motion
	reduced_motion_toggle.add_theme_color_override("font_color", GREEN)
	reduced_motion_toggle.toggled.connect(_on_reduced_motion_toggled)
	content.add_child(reduced_motion_toggle)
	var note := Label.new()
	note.text = "WASD move • Shift sprint • Space jump • RMB aim\n1/2/3 weapons • C crouch • Esc pause"
	note.add_theme_color_override("font_color", GREEN_SOFT)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)
	_update_settings_readout()

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		look_sensitivity = clamp(float(config.get_value("controls", "look_sensitivity", look_sensitivity)), 0.0008, 0.006)
		touchpad_mode = bool(config.get_value("controls", "touchpad_mode", false))
		mobile_auto_fire = bool(config.get_value("controls", "mobile_auto_fire", true))
		reduced_motion = bool(config.get_value("accessibility", "reduced_motion", false))
		high_score = int(config.get_value("progress", "high_score", 0))
		best_survival = float(config.get_value("progress", "best_survival", 0.0))

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("controls", "look_sensitivity", look_sensitivity)
	config.set_value("controls", "touchpad_mode", touchpad_mode)
	config.set_value("controls", "mobile_auto_fire", mobile_auto_fire)
	config.set_value("accessibility", "reduced_motion", reduced_motion)
	config.set_value("progress", "high_score", high_score)
	config.set_value("progress", "best_survival", best_survival)
	config.save(SETTINGS_PATH)

func _on_sensitivity_changed(value: float) -> void:
	look_sensitivity = value
	_update_settings_readout()
	_save_settings()

func _on_touchpad_toggled(enabled: bool) -> void:
	touchpad_mode = enabled
	if enabled and sensitivity_slider != null and sensitivity_slider.value > 0.0022:
		sensitivity_slider.value = 0.0016
	_update_settings_readout()
	_save_settings()

func _on_auto_fire_toggled(enabled: bool) -> void:
	mobile_auto_fire = enabled
	_save_settings()

func _on_reduced_motion_toggled(enabled: bool) -> void:
	reduced_motion = enabled
	_save_settings()

func _update_settings_readout() -> void:
	if sensitivity_value == null:
		return
	sensitivity_value.text = "CURRENT: %.4f   %s" % [look_sensitivity, "TRACKPAD CALIBRATED" if touchpad_mode else "MOUSE DEFAULT"]

func _show_title() -> void:
	hud_labels["center"].text = "NEON MALL\n\nPRESS ENTER TO DEPLOY"
	hud_labels["center"].add_theme_font_size_override("font_size", 30)
	hud_labels["objective"].text = "NATIONAL MALL // ENDLESS NIGHT"
	hud_labels["hint"].text = "WASD MOVE   SHIFT SPRINT   SPACE JUMP   RMB AIM   1/2/3 WEAPONS"
	hud_labels["stats"].text = ""
	hud_labels["top_right"].text = ""
	hud_labels["ammo"].text = ""
	settings_panel.visible = true

func _start_game() -> void:
	get_tree().paused = false
	game_started = true
	game_over = false
	paused = false
	survival_time = 0.0
	score = 0
	kills = 0
	shots = 0
	hits = 0
	streak = 0
	streak_timer = 0.0
	upgrade_pending = false
	next_upgrade_time = 120.0
	tension_timer = 2.5
	player.reset_player()
	director.reset_director()
	for projectile in projectile_pool:
		projectile.deactivate()
	for pickup in pickup_pool:
		pickup.deactivate()
	hud_labels["center"].text = ""
	hud_labels["center"].add_theme_font_size_override("font_size", 34)
	hud_labels["hint"].text = "SHIFT SPRINT   SPACE JUMP   RMB AIM   C CROUCH   1/2/3 WEAPONS"
	settings_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _restart_game() -> void:
	_start_game()

func _toggle_pause() -> void:
	paused = not paused
	get_tree().paused = paused
	if paused:
		hud_labels["center"].text = "PAUSED\n\nPRESS ESC TO RETURN"
		settings_panel.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		hud_labels["center"].text = ""
		settings_panel.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func player_died() -> void:
	game_over = true
	high_score = max(high_score, score)
	best_survival = maxf(best_survival, survival_time)
	_save_settings()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	hud_labels["center"].text = "YOU GOT SWARMED\n\nSCORE %06d   KILLS %03d\nTIME %02d:%02d   BEST %02d:%02d\nHIGH SCORE %06d\n\nCLICK TO REDEPLOY" % [score, kills, int(survival_time) / 60, int(survival_time) % 60, int(best_survival) / 60, int(best_survival) % 60, high_score]

func get_free_enemy() -> Node:
	for enemy in enemy_pool:
		if not enemy.active:
			return enemy
	return null

func fire_enemy_projectile(start: Vector3, target: Vector3, damage: int) -> void:
	for projectile in projectile_pool:
		if not projectile.active:
			projectile.activate(start, target, damage, 18.0 if survival_time > 180.0 else 14.0)
			return

func spawn_pickup(kind: String, at_position: Vector3) -> void:
	for pickup in pickup_pool:
		if not pickup.active:
			pickup.activate(kind, at_position)
			return

func pickup_collected(kind: String) -> void:
	play_sound("pickup", 1.15 if kind == "rapid" else 1.0)
	hud_labels["hint"].text = ("RAPID INK UPGRADED" if kind == "rapid" else "+30 HEALTH" if kind == "health" else "AMMUNITION RESTORED")

func play_sound(cue: String, pitch := 1.0) -> void:
	if audio_manager != null:
		audio_manager.play_cue(cue, pitch)

func enemy_defeated(enemy_score: int, enemy_type: String, at_position: Vector3) -> void:
	add_kill(enemy_score)
	play_sound("death", 0.72 if enemy_type == "bruiser" or enemy_type == "elite" else 1.0)
	if kills % 6 == 0:
		var kind := "health" if player.health < player.max_health * 0.48 else "rapid" if kills % 18 == 0 else "ammo"
		spawn_pickup(kind, at_position)

func add_kill(enemy_score: int) -> void:
	kills += 1
	streak = streak + 1 if streak_timer > 0.0 else 1
	streak_timer = 3.25
	score += enemy_score + int(survival_time * 2.0) + max(0, streak - 1) * 25
	if kills % 8 == 0:
		player.apply_pickup("ammo")
		hud_labels["hint"].text = "+18 INK CELLS // STREAK SUPPLY"
	if kills % 12 == 0:
		player.health = mini(player.max_health, player.health + 15)

func register_hit(_world_position: Vector3, critical := false) -> void:
	if ink_hud != null:
		ink_hud.show_hit(critical)
	play_sound("critical" if critical else "hit")

func player_damaged() -> void:
	if ink_hud != null:
		ink_hud.show_damage()

func elite_spawned() -> void:
	if ink_hud != null:
		ink_hud.show_elite()
	hud_labels["objective"].text = "WARNING // ELITE MASS INBOUND"
	play_sound("elite")

func _show_upgrade_choice() -> void:
	upgrade_pending = true
	paused = true
	upgrade_choices.clear()
	if int(next_upgrade_time / 120.0) % 2 == 1:
		upgrade_choices.append("damage")
		upgrade_choices.append("speed")
		upgrade_choices.append("magazine")
	else:
		upgrade_choices.append("health")
		upgrade_choices.append("fire_rate")
		upgrade_choices.append("damage")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	hud_labels["center"].text = "CHOOSE FIELD MOD\n\n[1] %s\n[2] %s\n[3] %s" % [_upgrade_label(upgrade_choices[0]), _upgrade_label(upgrade_choices[1]), _upgrade_label(upgrade_choices[2])]
	hud_labels["hint"].text = "SELECT ONE UPGRADE // TOUCH ANY THIRD OF THE SCREEN"

func select_upgrade(index: int) -> void:
	if not upgrade_pending or index < 0 or index >= upgrade_choices.size():
		return
	var choice := upgrade_choices[index]
	player.apply_upgrade(choice)
	upgrade_pending = false
	paused = false
	next_upgrade_time += 120.0
	hud_labels["center"].text = ""
	hud_labels["hint"].text = "%s INSTALLED" % _upgrade_label(choice)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	play_sound("pickup", 1.35)

func _upgrade_label(kind: String) -> String:
	if kind == "damage":
		return "+20% DAMAGE"
	if kind == "speed":
		return "+12% MOVE SPEED"
	if kind == "magazine":
		return "LARGER MAGAZINES"
	if kind == "health":
		return "+25 MAX HEALTH"
	return "+15% FIRE RATE"

func spawn_ink_burst(world_position: Vector3, burst_scale: float) -> void:
	var burst := Node3D.new()
	burst.name = "InkDeathBurst"
	add_child(burst)
	burst.global_position = world_position
	for i in range(10):
		var shard := MeshInstance3D.new()
		var shard_mesh := BoxMesh.new()
		var shard_scale: float = minf(1.8, burst_scale)
		shard_mesh.size = Vector3(0.07, 0.07, 0.8 + float(i % 3) * 0.28) * shard_scale
		shard.mesh = shard_mesh
		shard.material_override = _make_material(GREEN, 3.2)
		var angle := float(i) / 10.0 * TAU
		shard.rotation = Vector3(angle * 0.31, angle, angle * 0.17)
		burst.add_child(shard)
		var target: Vector3 = Vector3(cos(angle) * 2.0, sin(angle * 2.0) * 1.4, sin(angle) * 2.0) * minf(1.5, burst_scale)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(shard, "position", target, 0.32)
		tween.tween_property(shard, "scale", Vector3.ZERO, 0.38)
	get_tree().create_timer(0.42).timeout.connect(func():
		if is_instance_valid(burst):
			burst.queue_free()
	)

func _update_hud() -> void:
	if not is_instance_valid(player):
		return
	var tier := int(survival_time / 60.0) + 1
	var accuracy := 0
	if shots > 0:
		accuracy = int(round(float(hits) / float(shots) * 100.0))
	hud_labels["stats"].text = "SURVIVAL %02d:%02d    KILLS %03d    ACC %03d%%    TIER %02d" % [int(survival_time) / 60, int(survival_time) % 60, kills, accuracy, tier]
	hud_labels["top_right"].text = "SCORE: %06d" % score
	var stance := "ADS" if player.is_aiming else "SPRINT" if player.is_sprinting else "CROUCH" if player.is_crouching else "READY"
	hud_labels["ammo"].text = "%s  [%d]  %s\nHP %03d  SH %03d  AMMO %02d/%03d  STREAK x%02d" % [player.get_weapon_name(), player.current_weapon + 1, stance, player.health, player.shield, player.ammo, player.reserve_ammo, streak]
	if player.reloading:
		hud_labels["ammo"].text += "    RELOADING"
