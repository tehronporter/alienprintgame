extends Node3D

const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const SpawnDirector = preload("res://scripts/spawn_director.gd")

const GREEN := Color("#7dff35")
const GREEN_SOFT := Color("#2aa83d")
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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
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
	_make_box("MallGround", Vector3(0, -0.6, 0), Vector3(110, 1, 110), GREEN_SOFT, 0.03)
	_make_box("ReflectingPool", Vector3(0, -0.03, -5), Vector3(8, 0.12, 82), Color("#07130b"), 0.18)
	_make_landmark("LincolnMemorial", Vector3(0, 0, -47), Vector3(13, 9, 5), 12)
	_make_landmark("WashingtonMonument", Vector3(0, 0, 38), Vector3(4, 26, 4), 4)
	_make_path_lines()
	_make_cover()
	_make_lamps()

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

func _make_landmark(label: String, pos: Vector3, size: Vector3, columns: int) -> void:
	_make_box(label + "Core", pos, size, GREEN_SOFT, 0.08)
	var line_color := GREEN
	for i in range(columns):
		var x: float = pos.x - size.x * 0.42 + (float(i) / float(max(1, columns - 1))) * size.x * 0.84
		_make_box(label + "Column" + str(i), Vector3(x, pos.y + size.y * 0.12, pos.z - size.z * 0.55), Vector3(0.38, size.y * 0.72, 0.28), line_color, 1.8)
	_make_box(label + "TopLine", Vector3(pos.x, pos.y + size.y * 0.52, pos.z - size.z * 0.58), Vector3(size.x * 1.08, 0.32, 0.32), line_color, 2.0)
	_make_box(label + "Step", Vector3(pos.x, 0.25, pos.z + size.z * 0.25), Vector3(size.x * 1.4, 0.35, size.z * 0.8), GREEN_SOFT, 0.2)

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
		_make_box("Wreckage", pos, Vector3(2.8, 1.8, 1.5), GREEN_SOFT, 0.12).rotation.y = angle

func _make_lamps() -> void:
	for x in [-31.0, -24.0, 24.0, 31.0]:
		for z in [-36.0, -18.0, 18.0, 36.0]:
			_make_box("LampPost", Vector3(x, 3.0, z), Vector3(0.18, 6.0, 0.18), GREEN, 1.8)
			_make_box("LampHead", Vector3(x, 6.1, z), Vector3(0.75, 0.18, 0.75), GREEN, 2.4)

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
	for spec in [["stats", Vector2(28, 22), 18], ["objective", Vector2(0, 24), 20], ["ammo", Vector2(-220, -70), 22], ["hint", Vector2(0, -48), 18], ["center", Vector2(0, -10), 34]]:
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
			label.position += spec[1]
		elif spec[0] == "hint":
			label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.position += spec[1]
		else:
			label.position = spec[1]
		root.add_child(label)
		hud_labels[spec[0]] = label
	crosshair = hud_labels["center"]
	crosshair.text = "+"

func _show_title() -> void:
	hud_labels["center"].text = "NEON MALL\n\nPRESS ENTER TO DEPLOY"
	hud_labels["center"].add_theme_font_size_override("font_size", 30)
	hud_labels["objective"].text = "NATIONAL MALL // ENDLESS NIGHT"
	hud_labels["hint"].text = "WASD MOVE   MOUSE AIM   LMB FIRE   R RELOAD   ESC PAUSE"
	hud_labels["stats"].text = ""
	hud_labels["ammo"].text = ""

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
	hud_labels["center"].text = "+"
	hud_labels["center"].add_theme_font_size_override("font_size", 34)
	hud_labels["hint"].text = "WASD MOVE   MOUSE AIM   LMB FIRE   R RELOAD   ESC PAUSE"
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _restart_game() -> void:
	_start_game()

func _toggle_pause() -> void:
	paused = not paused
	get_tree().paused = paused
	if paused:
		hud_labels["center"].text = "PAUSED\n\nPRESS ESC TO RETURN"
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		hud_labels["center"].text = "+"
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
	hud_labels["stats"].text = "SURVIVAL %02d:%02d    SCORE %06d    KILLS %03d    TIER %02d" % [int(survival_time) / 60, int(survival_time) % 60, score, kills, tier]
	hud_labels["ammo"].text = "HP %03d    AMMO %02d / 120" % [player.health, player.ammo]
	if player.reloading:
		hud_labels["ammo"].text += "    RELOADING"
