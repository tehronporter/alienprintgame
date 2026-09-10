extends CharacterBody3D

var main: Node
var active := false
var enemy_type := "scout"
var health := 50
var move_speed := 2.5
var attack_damage := 8
var attack_cooldown := 0.0
var attack_range := 1.8
var visual_root: Node3D
var body_mesh: MeshInstance3D
var eye_mesh: MeshInstance3D

func _ready() -> void:
	_build_body()

func _build_body() -> void:
	visual_root = Node3D.new()
	visual_root.name = "HandDrawnAlien"
	add_child(visual_root)
	body_mesh = MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.42
	body.height = 1.1
	body_mesh.mesh = body
	body_mesh.position.y = 1.05
	body_mesh.material_override = _material(Color("#031108"), 0.28)
	visual_root.add_child(body_mesh)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.52
	head_mesh.height = 0.8
	head.mesh = head_mesh
	head.position = Vector3(0, 1.92, -0.03)
	head.scale = Vector3(0.82, 1.0, 0.72)
	head.material_override = _material(Color("#020904"), 0.25)
	visual_root.add_child(head)
	eye_mesh = MeshInstance3D.new()
	var eyes := BoxMesh.new()
	eyes.size = Vector3(0.62, 0.16, 0.12)
	eye_mesh.mesh = eyes
	eye_mesh.position = Vector3(0, 1.95, -0.45)
	eye_mesh.material_override = _material(Color("#baff74"), 3.4)
	visual_root.add_child(eye_mesh)
	_alien_part(Vector3(-0.62, 1.12, -0.02), Vector3(0.14, 1.0, 0.14), Vector3(0, 0, -0.28), Color("#7dff35"), 1.3)
	_alien_part(Vector3(0.62, 1.12, -0.02), Vector3(0.14, 1.0, 0.14), Vector3(0, 0, 0.28), Color("#7dff35"), 1.3)
	_alien_part(Vector3(-0.26, 0.16, -0.02), Vector3(0.16, 1.2, 0.16), Vector3(0, 0, -0.08), Color("#7dff35"), 1.1)
	_alien_part(Vector3(0.26, 0.16, -0.02), Vector3(0.16, 1.2, 0.16), Vector3(0, 0, 0.08), Color("#7dff35"), 1.1)
	_alien_part(Vector3(-0.88, 1.02, -0.08), Vector3(0.32, 0.12, 0.32), Vector3(0, 0, 0), Color("#7dff35"), 1.7)
	_alien_part(Vector3(0.88, 1.02, -0.08), Vector3(0.32, 0.12, 0.32), Vector3(0, 0, 0), Color("#7dff35"), 1.7)

func _alien_part(pos: Vector3, size: Vector3, rotation: Vector3, color: Color, energy: float) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = pos
	part.rotation = rotation
	part.material_override = _material(color, energy)
	visual_root.add_child(part)
	return part
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)

func _material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat

func activate(kind: String, spawn_position: Vector3, tier: int) -> void:
	enemy_type = kind
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	global_position = spawn_position
	attack_cooldown = 0.0
	var multiplier := 1.0 + float(tier - 1) * 0.14
	if kind == "scout":
		health = int(35 * multiplier)
		move_speed = 4.4 + float(tier - 1) * 0.18
		attack_damage = 5 + tier
		visual_root.scale = Vector3(0.72, 0.72, 0.72)
	elif kind == "bruiser":
		health = int(150 * multiplier)
		move_speed = 1.45 + float(tier - 1) * 0.1
		attack_damage = 15 + tier * 2
		visual_root.scale = Vector3(1.8, 1.8, 1.8)
	elif kind == "elite":
		health = int(280 * multiplier)
		move_speed = 2.2 + float(tier - 1) * 0.15
		attack_damage = 25 + tier * 2
		visual_root.scale = Vector3(2.2, 2.2, 2.2)
	else:
		health = int(70 * multiplier)
		move_speed = 2.4 + float(tier - 1) * 0.15
		attack_damage = 9 + tier
		visual_root.scale = Vector3.ONE

func deactivate() -> void:
	active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func _physics_process(delta: float) -> void:
	if not active or main.game_over or main.paused:
		return
	if attack_cooldown > 0:
		attack_cooldown -= delta
	var to_player: Vector3 = main.player.global_position - global_position
	to_player.y = 0
	var distance := to_player.length()
	if distance > attack_range:
		velocity = to_player.normalized() * move_speed
		look_at(Vector3(main.player.global_position.x, global_position.y, main.player.global_position.z), Vector3.UP)
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		if attack_cooldown <= 0:
			main.player.take_damage(attack_damage)
			attack_cooldown = 0.8 if enemy_type == "scout" else 1.2

func take_damage(amount: int) -> void:
	if not active:
		return
	health -= amount
	if health <= 0:
		main.add_kill(_score_value())
		deactivate()

func _score_value() -> int:
	if enemy_type == "elite":
		return 1000
	if enemy_type == "bruiser":
		return 300
	if enemy_type == "scout":
		return 125
	return 200
