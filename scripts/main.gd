extends Node3D

const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const SpawnDirector = preload("res://scripts/spawn_director.gd")

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
const SETTINGS_PATH := "user://neon_mall_settings.cfg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_load_settings()
	_build_world()
	_build_player()
	_build_enemy_pool()
	_build_hud()
	_show_title()

func _process(delta: float) -> void:
	if not game_started or game_over or paused:
		return
	survival_time += delta
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and game_started and not game_over:
		_toggle_pause()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER and not game_started:
		_start_game()
	if event.is_action_pressed("fire") and game_started and game_over:
		_restart_game()

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
	_make_landmark("WashingtonMonument", Vector3(0, 0, 38), Vector3(4, 26, 4), 4)
	_make_path_lines()
	_make_cover()
	_make_lamps()
	_make_tree_line()
	_make_flags()
	_make_ground_doodles()
	_make_ufo(Vector3(-24, 17, -22), 1.2)
	_make_ufo(Vector3(24, 20, 4), 0.8)

func _make_material(color: Color, emission_energy := 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = emission_energy
	material.roughness = 1.0
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

func _make_path_lines() -> void:
	for x in [-18.0, -9.0, 9.0, 18.0]:
		_make_box("MallPath", Vector3(x, 0.02, 0), Vector3(0.18, 0.05, 92), GREEN, 1.5)
	for z in [-28.0, -12.0, 12.0, 28.0]:
		_make_box("CrossPath", Vector3(0, 0.03, z), Vector3(72, 0.05, 0.18), GREEN, 1.5)

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
	for spec in [["stats", Vector2(28, 22), 18], ["top_right", Vector2(-32, 22), 18], ["objective", Vector2(0, 24), 20], ["ammo", Vector2(-220, -70), 22], ["hint", Vector2(0, -48), 18], ["center", Vector2(0, -10), 34]]:
		var label := Label.new()
		label.name = spec[0]
		label.add_theme_color_override("font_color", GREEN)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.add_theme_font_size_override("font_size", spec[2])
		if spec[0] == "objective" or spec[0] == "center":
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.set_anchors_preset(Control.PRESET_CENTER)
			label.position += spec[1]
		elif spec[0] == "ammo":
			label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			label.offset_left = -360
			label.offset_right = -20
			label.offset_top = -80
			label.offset_bottom = -30
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
	crosshair = hud_labels["center"]
	crosshair.text = "⊕"

func _build_settings_panel(root: Control) -> void:
	settings_panel = PanelContainer.new()
	settings_panel.name = "ControlSettings"
	settings_panel.position = Vector2(28, 150)
	settings_panel.size = Vector2(360, 205)
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
	var note := Label.new()
	note.text = "WASD move  •  Mouse/trackpad aim  •  Esc pause"
	note.add_theme_color_override("font_color", GREEN_SOFT)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)
	_update_settings_readout()

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		look_sensitivity = clamp(float(config.get_value("controls", "look_sensitivity", look_sensitivity)), 0.0008, 0.006)
		touchpad_mode = bool(config.get_value("controls", "touchpad_mode", false))

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("controls", "look_sensitivity", look_sensitivity)
	config.set_value("controls", "touchpad_mode", touchpad_mode)
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

func _update_settings_readout() -> void:
	if sensitivity_value == null:
		return
	sensitivity_value.text = "CURRENT: %.4f   %s" % [look_sensitivity, "TRACKPAD CALIBRATED" if touchpad_mode else "MOUSE DEFAULT"]

func _show_title() -> void:
	hud_labels["center"].text = "NEON MALL\n\nPRESS ENTER TO DEPLOY"
	hud_labels["center"].add_theme_font_size_override("font_size", 30)
	hud_labels["objective"].text = "NATIONAL MALL // ENDLESS NIGHT"
	hud_labels["hint"].text = "WASD MOVE   MOUSE AIM   LMB FIRE   R RELOAD   ESC PAUSE"
	hud_labels["stats"].text = ""
	hud_labels["top_right"].text = ""
	hud_labels["ammo"].text = ""
	settings_panel.visible = true

func _start_game() -> void:
	game_started = true
	game_over = false
	paused = false
	survival_time = 0.0
	score = 0
	kills = 0
	shots = 0
	hits = 0
	player.reset_player()
	director.reset_director()
	hud_labels["center"].text = "⊕"
	hud_labels["center"].add_theme_font_size_override("font_size", 34)
	hud_labels["hint"].text = "WASD MOVE   MOUSE AIM   LMB FIRE   R RELOAD   ESC PAUSE"
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
		hud_labels["center"].text = "⊕"
		settings_panel.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func player_died() -> void:
	game_over = true
	high_score = max(high_score, score)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	hud_labels["center"].text = "YOU GOT SWARMED\n\nSCORE %06d\nHIGH SCORE %06d\n\nCLICK TO REDEPLOY" % [score, high_score]

func get_free_enemy() -> Node:
	for enemy in enemy_pool:
		if not enemy.active:
			return enemy
	return null

func add_kill(enemy_score: int) -> void:
	kills += 1
	score += enemy_score + int(survival_time * 2.0)

func _update_hud() -> void:
	if not is_instance_valid(player):
		return
	var tier := int(survival_time / 60.0) + 1
	var accuracy := 0
	if shots > 0:
		accuracy = int(round(float(hits) / float(shots) * 100.0))
	hud_labels["stats"].text = "SURVIVAL %02d:%02d    KILLS %03d    ACC %03d%%    TIER %02d" % [int(survival_time) / 60, int(survival_time) % 60, kills, accuracy, tier]
	hud_labels["top_right"].text = "SCORE: %06d" % score
	hud_labels["ammo"].text = "HP %03d    AMMO %02d / %03d" % [player.health, player.ammo, player.reserve_ammo]
	if player.reloading:
		hud_labels["ammo"].text += "    RELOADING"
