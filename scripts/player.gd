extends CharacterBody3D

var main: Node
var health := 100
var ammo := 24
var reserve_ammo := 120
var reloading := false
var fire_cooldown := 0.0
var reload_timer := 0.0
var pitch := 0.0
var yaw := 0.0
var camera: Camera3D
var weapon: Node3D
var weapon_body: MeshInstance3D
var weapon_flash: MeshInstance3D
var weapon_base_position := Vector3(0.54, -0.5, -1.42)
var bob_time := 0.0
var recoil := 0.0
var damage_kick := 0.0
var hurt_cooldown := 0.0

const SPEED := 8.0
const GRAVITY := 20.0
const FIRE_RATE := 0.13

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.55, 0)
	camera.fov = 68.0
	camera.current = true
	add_child(camera)
	weapon = Node3D.new()
	weapon.name = "InkWeapon"
	weapon.position = weapon_base_position
	weapon.scale = Vector3(0.72, 0.72, 0.72)
	weapon.rotation_degrees = Vector3(-7, 0, 0)
	camera.add_child(weapon)
	weapon_body = _weapon_part(Vector3(0, 0, 0), Vector3(0.48, 0.3, 1.05), Color("#020904"), 0.15)
	weapon_body.rotation_degrees = Vector3(0, 0, -3)
	_weapon_outline(Vector3(0, 0, 0), Vector3(0.52, 0.34, 1.08), Color("#7dff35"), 2.1)
	_weapon_part(Vector3(0, 0.2, -0.14), Vector3(0.28, 0.12, 0.42), Color("#020904"), 0.15)
	_weapon_outline(Vector3(0, 0.2, -0.14), Vector3(0.3, 0.14, 0.44), Color("#baff74"), 2.5)
	_weapon_part(Vector3(0, -0.25, 0.22), Vector3(0.22, 0.45, 0.27), Color("#020904"), 0.15).rotation.x = -0.25
	_weapon_outline(Vector3(0, -0.25, 0.22), Vector3(0.24, 0.47, 0.29), Color("#7dff35"), 1.8)
	_weapon_part(Vector3(0, 0.0, -0.72), Vector3(0.18, 0.18, 0.55), Color("#020904"), 0.15)
	_weapon_outline(Vector3(0, 0.0, -0.72), Vector3(0.2, 0.2, 0.57), Color("#7dff35"), 2.2)
	for rib in range(4):
		_weapon_part(Vector3(0, 0.17, -0.43 - float(rib) * 0.14), Vector3(0.34, 0.045, 0.045), Color("#7dff35"), 1.8).rotation.z = float(rib - 2) * 0.025
	# Visible glove/forearm anchors the first-person pose.
	_weapon_part(Vector3(0.31, -0.27, 0.16), Vector3(0.3, 0.28, 0.48), Color("#031108"), 0.2).rotation.z = -0.32
	_weapon_outline(Vector3(0.31, -0.27, 0.16), Vector3(0.32, 0.3, 0.5), Color("#164d20"), 1.3)
	_weapon_part(Vector3(-0.3, -0.18, -0.42), Vector3(0.25, 0.22, 0.42), Color("#031108"), 0.2).rotation.z = 0.22
	_weapon_outline(Vector3(-0.3, -0.18, -0.42), Vector3(0.27, 0.24, 0.44), Color("#164d20"), 1.3)
	weapon_flash = _weapon_part(Vector3(0, 0.01, -0.92), Vector3(0.34, 0.24, 0.12), Color("#baff74"), 5.0)
	weapon_flash.visible = false

func _material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func reset_player() -> void:
	health = 100
	ammo = 24
	reserve_ammo = 120
	reloading = false
	reload_timer = 0.0
	velocity = Vector3.ZERO
	position = Vector3(0, 1.5, 18)
	yaw = 0.0
	pitch = 0.0
	rotation = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	weapon.position = weapon_base_position
	recoil = 0.0
	damage_kick = 0.0
	hurt_cooldown = 0.0

func _weapon_part(offset: Vector3, size: Vector3, color: Color, energy: float) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = offset
	part.material_override = _material(color, energy)
	weapon.add_child(part)
	return part

func _weapon_outline(offset: Vector3, size: Vector3, color: Color, energy: float) -> void:
	var width := 0.018
	for y in [-size.y * 0.5, size.y * 0.5]:
		for z in [-size.z * 0.5, size.z * 0.5]:
			_weapon_part(offset + Vector3(0, y, z), Vector3(size.x, width, width), color, energy)
	for x in [-size.x * 0.5, size.x * 0.5]:
		for z in [-size.z * 0.5, size.z * 0.5]:
			_weapon_part(offset + Vector3(x, 0, z), Vector3(width, size.y, width), color, energy)
	for x in [-size.x * 0.5, size.x * 0.5]:
		for y in [-size.y * 0.5, size.y * 0.5]:
			_weapon_part(offset + Vector3(x, y, 0), Vector3(width, width, size.z), color, energy)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and main.game_started and not main.game_over and not main.paused:
		var sensitivity: float = main.look_sensitivity * (0.58 if main.touchpad_mode else 1.0)
		yaw -= event.relative.x * sensitivity
		pitch = clamp(pitch - event.relative.y * sensitivity, -1.35, 1.35)
		rotation.y = yaw
		camera.rotation.x = pitch
	if event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		main.mobile_controls_visible = not main.mobile_controls_visible

func _physics_process(delta: float) -> void:
	if not main.game_started or main.game_over or main.paused:
		return
	if fire_cooldown > 0.0:
		fire_cooldown -= delta
	if recoil > 0.0:
		recoil = max(0.0, recoil - delta * 7.0)
	if damage_kick > 0.0:
		damage_kick = max(0.0, damage_kick - delta * 5.0)
	if hurt_cooldown > 0.0:
		hurt_cooldown = max(0.0, hurt_cooldown - delta)
	bob_time += delta * (4.0 if velocity.length() > 0.2 else 1.5)
	if reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()
	if main.mobile_look_delta.length() > 0.0:
		var mobile_sensitivity: float = main.look_sensitivity * 0.72
		yaw -= main.mobile_look_delta.x * mobile_sensitivity
		pitch = clamp(pitch - main.mobile_look_delta.y * mobile_sensitivity, -1.35, 1.35)
		rotation.y = yaw
		camera.rotation.x = pitch
		main.mobile_look_delta = Vector2.ZERO
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if main.mobile_move_vector.length() > 0.05:
		input_vec = main.mobile_move_vector
	var direction := (transform.basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0
	move_and_slide()
	global_position.x = clamp(global_position.x, -48.0, 48.0)
	global_position.z = clamp(global_position.z, -48.0, 48.0)
	var moving := Vector2(velocity.x, velocity.z).length() > 0.2
	var bob := Vector3(sin(bob_time) * 0.018, abs(cos(bob_time)) * (0.016 if moving else 0.004), 0)
	weapon.position = weapon_base_position + bob + Vector3(damage_kick * 0.04, -damage_kick * 0.025, recoil * 0.12)
	weapon.rotation_degrees.x = -7.0 + recoil * 8.0 + damage_kick * 3.0
	camera.position = Vector3(sin(bob_time * 11.0) * damage_kick * 0.015, 1.55 + cos(bob_time * 9.0) * damage_kick * 0.012, 0)
	if Input.is_action_pressed("fire"):
		_fire()
	if main.mobile_fire:
		_fire()
	if Input.is_action_just_pressed("reload"):
		_start_reload()
	if main.mobile_reload:
		_start_reload()
		main.mobile_reload = false

func _fire() -> void:
	if reloading or fire_cooldown > 0.0:
		return
	if ammo <= 0:
		_start_reload()
		return
	ammo -= 1
	main.shots += 1
	fire_cooldown = FIRE_RATE
	recoil = 1.0
	weapon_flash.visible = true
	get_tree().create_timer(0.045).timeout.connect(func():
		if is_instance_valid(weapon_flash):
			weapon_flash.visible = false
	)
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_transform.basis.z * 100.0)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.has_method("take_damage"):
		hit.collider.take_damage(25)
		main.hits += 1

func _start_reload() -> void:
	if reloading or ammo >= 24 or reserve_ammo <= 0:
		return
	reloading = true
	reload_timer = 1.1

func _finish_reload() -> void:
	var needed := 24 - ammo
	var loaded: int = min(needed, reserve_ammo)
	ammo += loaded
	reserve_ammo -= loaded
	reloading = false

func take_damage(amount: int) -> void:
	if main.game_over or hurt_cooldown > 0.0:
		return
	health = max(0, health - amount)
	hurt_cooldown = 0.62
	damage_kick = 1.0
	if main.has_method("player_damaged"):
		main.player_damaged()
	if health <= 0:
		main.player_died()
