extends CharacterBody3D

const GREEN := Color("#7dff35")
const GREEN_HOT := Color("#c4ff82")
const GREEN_DARK := Color("#020b04")

var main: Node
var active := false
var enemy_type := "scout"
var health := 50
var move_speed := 2.5
var attack_damage := 8
var attack_cooldown := 0.0
var attack_range := 1.8
var visual_root: Node3D
var eye_mesh: MeshInstance3D
var collision_shape: CollisionShape3D
var ink_parts: Array[MeshInstance3D] = []
var motion_time := 0.0
var hit_flash := 0.0

func _ready() -> void:
	_build_body()

func _build_body() -> void:
	visual_root = Node3D.new()
	visual_root.name = "HandDrawnAlien"
	add_child(visual_root)
	_capsule_part(Vector3(0, 1.02, 0), 0.43, 1.18, GREEN_DARK, 0.12)
	var chest := _part(Vector3(0, 1.25, -0.12), Vector3(0.76, 0.46, 0.18), GREEN, 1.45)
	chest.rotation.z = -0.035
	_sphere_part(Vector3(0, 1.93, -0.04), Vector3(0.9, 1.0, 0.76), 0.56, GREEN_DARK, 0.1)
	eye_mesh = _part(Vector3(-0.2, 1.98, -0.48), Vector3(0.29, 0.12, 0.08), GREEN_HOT, 3.8)
	eye_mesh.rotation.z = -0.16
	var right_eye := _part(Vector3(0.2, 1.98, -0.48), Vector3(0.29, 0.12, 0.08), GREEN_HOT, 3.8)
	right_eye.rotation.z = 0.16
	_part(Vector3(0, 1.74, -0.49), Vector3(0.22, 0.05, 0.06), GREEN, 1.9)
	var left_arm := _part(Vector3(-0.61, 1.12, -0.02), Vector3(0.14, 1.08, 0.14), GREEN, 1.4)
	left_arm.rotation.z = -0.25
	var right_arm := _part(Vector3(0.61, 1.12, -0.02), Vector3(0.14, 1.08, 0.14), GREEN, 1.4)
	right_arm.rotation.z = 0.22
	_part(Vector3(-0.82, 1.52, -0.05), Vector3(0.38, 0.15, 0.42), GREEN, 1.8).rotation.z = -0.18
	_part(Vector3(0.82, 1.52, -0.05), Vector3(0.38, 0.15, 0.42), GREEN, 1.8).rotation.z = 0.14
	_part(Vector3(-0.25, 0.25, 0), Vector3(0.16, 1.16, 0.16), GREEN, 1.35).rotation.z = -0.07
	_part(Vector3(0.25, 0.25, 0), Vector3(0.16, 1.16, 0.16), GREEN, 1.35).rotation.z = 0.08
	_part(Vector3(-0.28, -0.3, -0.12), Vector3(0.42, 0.14, 0.7), GREEN, 1.7)
	_part(Vector3(0.28, -0.3, -0.12), Vector3(0.42, 0.14, 0.7), GREEN, 1.7)
	_part(Vector3(0.12, 1.02, -0.52), Vector3(1.24, 0.2, 0.18), GREEN_DARK, 0.2)
	_part(Vector3(0.16, 1.04, -0.61), Vector3(1.4, 0.07, 0.07), GREEN, 2.0).rotation.z = -0.07
	_part(Vector3(0.61, 1.0, -0.61), Vector3(0.14, 0.42, 0.1), GREEN, 1.8).rotation.z = -0.32
	_part(Vector3(-0.58, 1.04, -0.61), Vector3(0.36, 0.14, 0.12), GREEN_HOT, 2.4)
	for side in [-1.0, 1.0]:
		var cheek := _part(Vector3(side * 0.47, 1.91, -0.28), Vector3(0.08, 0.58, 0.08), GREEN, 1.5)
		cheek.rotation.z = side * 0.22
		var antenna := _part(Vector3(side * 0.26, 2.49, 0), Vector3(0.06, 0.48, 0.06), GREEN, 1.8)
		antenna.rotation.z = side * 0.28
	collision_shape = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.58
	capsule.height = 2.55
	collision_shape.shape = capsule
	collision_shape.position.y = 0.92
	add_child(collision_shape)

func _part(pos: Vector3, size: Vector3, color: Color, energy: float) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = pos
	part.material_override = _material(color, energy)
	visual_root.add_child(part)
	if color != GREEN_DARK:
		ink_parts.append(part)
	return part

func _capsule_part(pos: Vector3, radius: float, height: float, color: Color, energy: float) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 3
	part.mesh = mesh
	part.position = pos
	part.material_override = _material(color, energy)
	visual_root.add_child(part)
	return part

func _sphere_part(pos: Vector3, part_scale: Vector3, radius: float, color: Color, energy: float) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	part.mesh = mesh
	part.position = pos
	part.scale = part_scale
	part.material_override = _material(color, energy)
	visual_root.add_child(part)
	return part

func _material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func activate(kind: String, spawn_position: Vector3, tier: int) -> void:
	enemy_type = kind
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	global_position = spawn_position
	attack_cooldown = 0.0
	motion_time = float(get_instance_id() % 17)
	hit_flash = 0.0
	var multiplier := 1.0 + float(tier - 1) * 0.14
	var target_scale := Vector3.ONE
	if kind == "scout":
		health = int(35 * multiplier)
		move_speed = 4.4 + float(tier - 1) * 0.18
		attack_damage = 5 + tier
		target_scale = Vector3(0.7, 0.7, 0.7)
	elif kind == "bruiser":
		health = int(150 * multiplier)
		move_speed = 1.45 + float(tier - 1) * 0.1
		attack_damage = 15 + tier * 2
		target_scale = Vector3(1.65, 1.8, 1.65)
	elif kind == "elite":
		health = int(280 * multiplier)
		move_speed = 2.2 + float(tier - 1) * 0.15
		attack_damage = 25 + tier * 2
		target_scale = Vector3(2.05, 2.25, 2.05)
		if main.has_method("elite_spawned"):
			main.elite_spawned()
	else:
		health = int(70 * multiplier)
		move_speed = 2.4 + float(tier - 1) * 0.15
		attack_damage = 9 + tier
	visual_root.scale = target_scale
	collision_shape.scale = target_scale
	_modulate_ink(GREEN_HOT if kind == "elite" else GREEN)

func deactivate() -> void:
	active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func _physics_process(delta: float) -> void:
	if not active or main.game_over or main.paused:
		return
	motion_time += delta
	if hit_flash > 0.0:
		hit_flash = max(0.0, hit_flash - delta)
		if hit_flash <= 0.0:
			_modulate_ink(GREEN_HOT if enemy_type == "elite" else GREEN)
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	var to_player: Vector3 = main.player.global_position - global_position
	to_player.y = 0
	var distance := to_player.length()
	visual_root.position.y = sin(motion_time * (7.0 if enemy_type == "scout" else 4.2)) * 0.06
	visual_root.rotation.z = sin(motion_time * 2.3) * 0.035
	if distance > attack_range * visual_root.scale.x:
		velocity = to_player.normalized() * move_speed
		look_at(Vector3(main.player.global_position.x, global_position.y, main.player.global_position.z), Vector3.UP)
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		if attack_cooldown <= 0:
			main.player.take_damage(attack_damage)
			attack_cooldown = 0.8 if enemy_type == "scout" else 1.2
			var original_scale := visual_root.scale
			var tell := create_tween()
			tell.tween_property(visual_root, "scale", original_scale * Vector3(1.08, 0.92, 1.08), 0.08)
			tell.tween_property(visual_root, "scale", original_scale, 0.12)

func take_damage(amount: int) -> void:
	if not active:
		return
	health -= amount
	hit_flash = 0.08
	_modulate_ink(Color.WHITE)
	if main.has_method("register_hit"):
		main.register_hit(global_position + Vector3(0, 1.2, 0))
	if health <= 0:
		if main.has_method("spawn_ink_burst"):
			main.spawn_ink_burst(global_position + Vector3(0, 1.1, 0), visual_root.scale.x)
		main.add_kill(_score_value())
		deactivate()

func _modulate_ink(color: Color) -> void:
	for part in ink_parts:
		if is_instance_valid(part):
			part.material_override = _material(color, 4.5 if color == Color.WHITE else 2.0)

func _score_value() -> int:
	if enemy_type == "elite":
		return 1000
	if enemy_type == "bruiser":
		return 300
	if enemy_type == "scout":
		return 125
	return 200
