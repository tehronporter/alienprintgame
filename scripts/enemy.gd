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
var strafe_direction := 1.0
var variant_roots: Dictionary = {}

func _ready() -> void:
	_build_body()

func _build_body() -> void:
	visual_root = Node3D.new()
	visual_root.name = "HandDrawnAlien"
	add_child(visual_root)
	_capsule_part(Vector3(0, 1.02, 0), 0.43, 1.18, GREEN_DARK, 0.12)
	var chest := _part(Vector3(0, 1.25, -0.12), Vector3(0.76, 0.46, 0.18), GREEN_DARK, 0.12)
	chest.rotation.z = -0.035
	_part(Vector3(0, 1.47, -0.23), Vector3(0.72, 0.055, 0.055), GREEN, 1.7).rotation.z = -0.035
	_part(Vector3(0, 1.04, -0.23), Vector3(0.64, 0.055, 0.055), GREEN, 1.5).rotation.z = 0.035
	_sphere_part(Vector3(0, 1.93, -0.04), Vector3(0.9, 1.0, 0.76), 0.56, GREEN_DARK, 0.1)
	eye_mesh = _part(Vector3(-0.2, 1.98, -0.48), Vector3(0.29, 0.12, 0.08), GREEN_HOT, 3.8)
	eye_mesh.rotation.z = -0.16
	var right_eye := _part(Vector3(0.2, 1.98, -0.48), Vector3(0.29, 0.12, 0.08), GREEN_HOT, 3.8)
	right_eye.rotation.z = 0.16
	_part(Vector3(0, 1.74, -0.49), Vector3(0.22, 0.05, 0.06), GREEN, 1.9)
	var left_arm := _part(Vector3(-0.61, 1.12, -0.02), Vector3(0.14, 1.08, 0.14), GREEN_DARK, 0.12)
	left_arm.rotation.z = -0.25
	var right_arm := _part(Vector3(0.61, 1.12, -0.02), Vector3(0.14, 1.08, 0.14), GREEN_DARK, 0.12)
	right_arm.rotation.z = 0.22
	_part(Vector3(-0.82, 1.52, -0.05), Vector3(0.38, 0.15, 0.42), GREEN_DARK, 0.12).rotation.z = -0.18
	_part(Vector3(0.82, 1.52, -0.05), Vector3(0.38, 0.15, 0.42), GREEN_DARK, 0.12).rotation.z = 0.14
	_part(Vector3(-0.84, 1.59, -0.28), Vector3(0.36, 0.045, 0.045), GREEN, 1.7).rotation.z = -0.18
	_part(Vector3(0.84, 1.59, -0.28), Vector3(0.36, 0.045, 0.045), GREEN, 1.7).rotation.z = 0.14
	_part(Vector3(-0.25, 0.25, 0), Vector3(0.16, 1.16, 0.16), GREEN_DARK, 0.12).rotation.z = -0.07
	_part(Vector3(0.25, 0.25, 0), Vector3(0.16, 1.16, 0.16), GREEN_DARK, 0.12).rotation.z = 0.08
	# Thin offset bones preserve the black body mass and produce a drawn-outline read up close.
	_part(Vector3(-0.66, 1.11, -0.1), Vector3(0.055, 1.02, 0.055), GREEN, 1.5).rotation.z = -0.25
	_part(Vector3(0.66, 1.11, -0.1), Vector3(0.055, 1.02, 0.055), GREEN, 1.5).rotation.z = 0.22
	_part(Vector3(-0.29, 0.25, -0.09), Vector3(0.055, 1.12, 0.055), GREEN, 1.5).rotation.z = -0.07
	_part(Vector3(0.29, 0.25, -0.09), Vector3(0.055, 1.12, 0.055), GREEN, 1.5).rotation.z = 0.08
	_part(Vector3(-0.28, -0.3, -0.12), Vector3(0.42, 0.14, 0.7), GREEN_DARK, 0.12)
	_part(Vector3(0.28, -0.3, -0.12), Vector3(0.42, 0.14, 0.7), GREEN_DARK, 0.12)
	_part(Vector3(-0.28, -0.23, -0.49), Vector3(0.4, 0.045, 0.045), GREEN, 1.6)
	_part(Vector3(0.28, -0.23, -0.49), Vector3(0.4, 0.045, 0.045), GREEN, 1.6)
	_part(Vector3(0.12, 1.02, -0.52), Vector3(1.24, 0.2, 0.18), GREEN_DARK, 0.2)
	_part(Vector3(0.16, 1.04, -0.61), Vector3(1.4, 0.07, 0.07), GREEN, 2.0).rotation.z = -0.07
	_part(Vector3(0.61, 1.0, -0.61), Vector3(0.14, 0.42, 0.1), GREEN, 1.8).rotation.z = -0.32
	_part(Vector3(-0.58, 1.04, -0.61), Vector3(0.36, 0.14, 0.12), GREEN_HOT, 2.4)
	for side in [-1.0, 1.0]:
		var cheek := _part(Vector3(side * 0.47, 1.91, -0.28), Vector3(0.08, 0.58, 0.08), GREEN, 1.5)
		cheek.rotation.z = side * 0.22
		var antenna := _part(Vector3(side * 0.26, 2.49, 0), Vector3(0.06, 0.48, 0.06), GREEN, 1.8)
		antenna.rotation.z = side * 0.28
	_build_variant_details()
	collision_shape = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.58
	capsule.height = 2.55
	collision_shape.shape = capsule
	collision_shape.position.y = 0.92
	add_child(collision_shape)

func _build_variant_details() -> void:
	for kind in ["scout", "standard", "bruiser", "elite"]:
		var root := Node3D.new()
		root.name = kind.capitalize() + "Silhouette"
		visual_root.add_child(root)
		variant_roots[kind] = root
	var scout: Node3D = variant_roots["scout"]
	for side in [-1.0, 1.0]:
		var feeler := _detail_part(scout, Vector3(side * 0.42, 2.72, 0), Vector3(0.045, 0.72, 0.045), GREEN, 2.0)
		feeler.rotation.z = side * 0.42
		var claw := _detail_part(scout, Vector3(side * 0.86, 0.6, -0.08), Vector3(0.06, 0.58, 0.06), GREEN_HOT, 2.1)
		claw.rotation.z = side * 0.35
	var soldier: Node3D = variant_roots["standard"]
	for side in [-1.0, 1.0]:
		_detail_part(soldier, Vector3(side * 0.82, 1.58, -0.08), Vector3(0.52, 0.1, 0.48), GREEN_DARK, 0.12).rotation.z = side * 0.12
		_detail_part(soldier, Vector3(side * 0.82, 1.64, -0.34), Vector3(0.48, 0.045, 0.045), GREEN_HOT, 1.8).rotation.z = side * 0.12
	for rib in range(4):
		_detail_part(soldier, Vector3(-0.34 + float(rib) * 0.23, 1.33, -0.26), Vector3(0.07, 0.34, 0.06), GREEN, 1.7).rotation.z = -0.15
	var bruiser: Node3D = variant_roots["bruiser"]
	_detail_part(bruiser, Vector3(0, 1.38, -0.22), Vector3(1.25, 0.72, 0.2), GREEN_DARK, 0.12)
	for side in [-1.0, 1.0]:
		_detail_part(bruiser, Vector3(side * 0.83, 1.55, -0.15), Vector3(0.68, 0.34, 0.62), GREEN_DARK, 0.12).rotation.z = side * 0.15
		_detail_part(bruiser, Vector3(side * 0.83, 1.73, -0.48), Vector3(0.62, 0.055, 0.055), GREEN, 1.8).rotation.z = side * 0.15
		_detail_part(bruiser, Vector3(side * 0.83, 0.72, -0.2), Vector3(0.48, 0.52, 0.48), GREEN_DARK, 0.12)
		_detail_part(bruiser, Vector3(side * 0.83, 0.98, -0.46), Vector3(0.42, 0.055, 0.055), GREEN_HOT, 1.8)
		var horn := _detail_part(bruiser, Vector3(side * 0.34, 2.58, 0), Vector3(0.08, 0.62, 0.08), GREEN, 2.0)
		horn.rotation.z = side * 0.58
	var elite: Node3D = variant_roots["elite"]
	_detail_part(elite, Vector3(0, 1.36, -0.28), Vector3(1.42, 0.76, 0.18), GREEN_DARK, 0.1)
	_detail_part(elite, Vector3(0, 1.42, -0.42), Vector3(0.28, 0.28, 0.08), GREEN_HOT, 4.2)
	for side in [-1.0, 0.0, 1.0]:
		var crown := _detail_part(elite, Vector3(side * 0.42, 2.72 + (0.18 if side == 0.0 else 0.0), 0), Vector3(0.08, 0.75, 0.08), GREEN_HOT, 2.8)
		crown.rotation.z = side * 0.5
	for side in [-1.0, 1.0]:
		var mantle := _detail_part(elite, Vector3(side * 0.9, 1.55, -0.12), Vector3(0.78, 0.18, 0.72), GREEN_DARK, 0.12)
		mantle.rotation.z = side * 0.18
		var mantle_edge := _detail_part(elite, Vector3(side * 0.9, 1.66, -0.5), Vector3(0.72, 0.055, 0.055), GREEN_HOT, 2.3)
		mantle_edge.rotation.z = side * 0.18

func _detail_part(parent: Node3D, pos: Vector3, size: Vector3, color: Color, energy: float) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = pos
	part.material_override = _material(color, energy)
	parent.add_child(part)
	if color != GREEN_DARK:
		ink_parts.append(part)
	return part

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
	attack_cooldown = 0.8 + float(get_instance_id() % 7) * 0.11
	attack_range = 2.35
	motion_time = float(get_instance_id() % 17)
	strafe_direction = -1.0 if get_instance_id() % 2 == 0 else 1.0
	hit_flash = 0.0
	for variant_name in variant_roots:
		var variant: Node3D = variant_roots[variant_name]
		variant.visible = variant_name == kind
	var multiplier := 1.0 + float(tier - 1) * 0.14
	var target_scale := Vector3.ONE
	if kind == "scout":
		health = int(35 * multiplier)
		move_speed = 4.4 + float(tier - 1) * 0.18
		attack_damage = 5 + tier
		target_scale = Vector3(0.7, 0.7, 0.7)
		attack_range = 2.6
	elif kind == "bruiser":
		health = int(150 * multiplier)
		move_speed = 1.45 + float(tier - 1) * 0.1
		attack_damage = 15 + tier * 2
		target_scale = Vector3(1.65, 1.8, 1.65)
		attack_range = 1.7
	elif kind == "elite":
		health = int(280 * multiplier)
		move_speed = 2.2 + float(tier - 1) * 0.15
		attack_damage = 25 + tier * 2
		target_scale = Vector3(2.05, 2.25, 2.05)
		attack_range = 1.45
		if main.has_method("elite_spawned"):
			main.elite_spawned()
	else:
		health = int(70 * multiplier)
		move_speed = 2.4 + float(tier - 1) * 0.15
		attack_damage = 6 + tier
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
	look_at(Vector3(main.player.global_position.x, global_position.y, main.player.global_position.z), Vector3.UP)
	var separation := Vector3.ZERO
	for other in main.enemy_pool:
		if other != self and other.active:
			var offset: Vector3 = global_position - other.global_position
			offset.y = 0
			if offset.length_squared() > 0.01 and offset.length_squared() < 5.0:
				separation += offset.normalized() * 1.4
	var is_ranged := enemy_type == "standard" or enemy_type == "elite"
	var personal_space: float = 3.3 + maxf(0.0, visual_root.scale.x - 1.0) * 1.25
	if is_ranged and distance > 7.5:
		var forward := to_player.normalized()
		var side := Vector3(-forward.z, 0, forward.x) * strafe_direction
		var approach := forward if distance > (17.0 if enemy_type == "standard" else 13.0) else Vector3.ZERO
		velocity = (approach + side * 0.42 + separation).normalized() * move_speed
		move_and_slide()
		if attack_cooldown <= 0.0 and distance < 25.0:
			var phase: float = motion_time * 1.7 + float(get_instance_id() % 13)
			var aim_wobble := Vector3(sin(phase) * (0.55 if enemy_type == "elite" else 1.35), sin(phase * 0.7) * 0.35, cos(phase) * 0.28)
			main.fire_enemy_projectile(global_position + Vector3(0, 1.35 * visual_root.scale.y, 0), main.player.global_position + Vector3(0, 0.9, 0) + aim_wobble, attack_damage)
			attack_cooldown = 0.9 if enemy_type == "elite" else 2.15
	elif distance > maxf(attack_range * visual_root.scale.x, personal_space):
		velocity = (to_player.normalized() + separation).normalized() * move_speed
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

func take_damage(amount: int, critical := false) -> void:
	if not active:
		return
	health -= amount
	hit_flash = 0.08
	_modulate_ink(Color.WHITE)
	if main.has_method("register_hit"):
		main.register_hit(global_position + Vector3(0, 1.2, 0), critical)
	if health <= 0:
		if main.has_method("spawn_ink_burst"):
			main.spawn_ink_burst(global_position + Vector3(0, 1.1, 0), visual_root.scale.x)
		main.enemy_defeated(_score_value(), enemy_type, global_position)
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
