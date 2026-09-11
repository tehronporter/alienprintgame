extends CharacterBody3D

const GREEN := Color("#7dff35")
const HOT := Color("#c4ff82")
const DARK := Color("#020904")
const WALK_SPEED := 7.6
const SPRINT_SPEED := 11.2
const CROUCH_SPEED := 4.5
const GRAVITY := 20.0
const JUMP_VELOCITY := 7.2

var main: Node
var max_health := 100
var health := 100
var shield := 100
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
var current_weapon := 0
var damage_multiplier := 1.0
var speed_multiplier := 1.0
var fire_rate_multiplier := 1.0
var is_aiming := false
var is_crouching := false
var is_sprinting := false
var rng := RandomNumberGenerator.new()
var weapon_states: Array[Dictionary] = [
	{"name": "INK RIFLE", "ammo": 24, "reserve": 120, "mag": 24, "damage": 25, "fire_rate": 0.13, "reload": 1.1, "pellets": 1, "spread": 0.008},
	{"name": "MARKER SCATTERGUN", "ammo": 6, "reserve": 36, "mag": 6, "damage": 17, "fire_rate": 0.72, "reload": 1.45, "pellets": 7, "spread": 0.075},
	{"name": "SCRIBBLE PISTOL", "ammo": 12, "reserve": 96, "mag": 12, "damage": 34, "fire_rate": 0.24, "reload": 0.85, "pellets": 1, "spread": 0.014}
]

func _ready() -> void:
	rng.seed = 424242
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
	_build_weapon()

func _build_weapon() -> void:
	weapon = Node3D.new()
	weapon.name = "InkWeapon"
	weapon.position = weapon_base_position
	weapon.scale = Vector3(0.72, 0.72, 0.72)
	weapon.rotation_degrees = Vector3(-7, 0, 0)
	camera.add_child(weapon)
	weapon_body = _weapon_part(Vector3.ZERO, Vector3(0.48, 0.3, 1.05), DARK, 0.15)
	weapon_body.rotation_degrees = Vector3(0, 0, -3)
	_weapon_outline(Vector3.ZERO, Vector3(0.52, 0.34, 1.08), GREEN, 2.1)
	_weapon_part(Vector3(0, 0.2, -0.14), Vector3(0.28, 0.12, 0.42), DARK, 0.15)
	_weapon_outline(Vector3(0, 0.2, -0.14), Vector3(0.3, 0.14, 0.44), HOT, 2.5)
	_weapon_part(Vector3(0, -0.25, 0.22), Vector3(0.22, 0.45, 0.27), DARK, 0.15).rotation.x = -0.25
	_weapon_outline(Vector3(0, -0.25, 0.22), Vector3(0.24, 0.47, 0.29), GREEN, 1.8)
	_weapon_part(Vector3(0, 0, -0.72), Vector3(0.18, 0.18, 0.55), DARK, 0.15)
	_weapon_outline(Vector3(0, 0, -0.72), Vector3(0.2, 0.2, 0.57), GREEN, 2.2)
	for rib in range(4):
		_weapon_part(Vector3(0, 0.17, -0.43 - float(rib) * 0.14), Vector3(0.34, 0.045, 0.045), GREEN, 1.8).rotation.z = float(rib - 2) * 0.025
	_weapon_part(Vector3(0.31, -0.27, 0.16), Vector3(0.3, 0.28, 0.48), Color("#031108"), 0.2).rotation.z = -0.32
	_weapon_outline(Vector3(0.31, -0.27, 0.16), Vector3(0.32, 0.3, 0.5), Color("#164d20"), 1.3)
	_weapon_part(Vector3(-0.3, -0.18, -0.42), Vector3(0.25, 0.22, 0.42), Color("#031108"), 0.2).rotation.z = 0.22
	_weapon_outline(Vector3(-0.3, -0.18, -0.42), Vector3(0.27, 0.24, 0.44), Color("#164d20"), 1.3)
	weapon_flash = _weapon_part(Vector3(0, 0.01, -0.98), Vector3(0.34, 0.24, 0.12), HOT, 5.0)
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
	max_health = 100
	health = max_health
	shield = 100
	damage_multiplier = 1.0
	speed_multiplier = 1.0
	fire_rate_multiplier = 1.0
	weapon_states[0] = {"name": "INK RIFLE", "ammo": 24, "reserve": 120, "mag": 24, "damage": 25, "fire_rate": 0.13, "reload": 1.1, "pellets": 1, "spread": 0.008}
	weapon_states[1] = {"name": "MARKER SCATTERGUN", "ammo": 6, "reserve": 36, "mag": 6, "damage": 17, "fire_rate": 0.72, "reload": 1.45, "pellets": 7, "spread": 0.075}
	weapon_states[2] = {"name": "SCRIBBLE PISTOL", "ammo": 12, "reserve": 96, "mag": 12, "damage": 34, "fire_rate": 0.24, "reload": 0.85, "pellets": 1, "spread": 0.014}
	current_weapon = 0
	_load_weapon_state()
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
	is_aiming = false
	is_crouching = false
	is_sprinting = false
	_apply_weapon_pose()

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
		var sensitivity: float = main.look_sensitivity * (0.58 if main.touchpad_mode else 1.0) * (0.72 if is_aiming else 1.0)
		yaw -= event.relative.x * sensitivity
		pitch = clampf(pitch - event.relative.y * sensitivity, -1.35, 1.35)
		rotation.y = yaw
		camera.rotation.x = pitch
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F2:
			main.mobile_controls_visible = not main.mobile_controls_visible
		elif event.keycode == KEY_1:
			switch_weapon(0)
		elif event.keycode == KEY_2:
			switch_weapon(1)
		elif event.keycode == KEY_3:
			switch_weapon(2)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			switch_weapon((current_weapon + 2) % 3)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			switch_weapon((current_weapon + 1) % 3)

func _physics_process(delta: float) -> void:
	if not main.game_started or main.game_over or main.paused:
		return
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	recoil = maxf(0.0, recoil - delta * 7.0)
	damage_kick = maxf(0.0, damage_kick - delta * 5.0)
	hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
	if reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()
	_handle_look()
	_handle_movement(delta)
	_handle_weapon_pose(delta)
	if Input.is_action_pressed("fire") or main.mobile_fire:
		_fire()
	elif main.mobile_controls_visible and main.mobile_auto_fire and _target_under_reticle():
		_fire()
	if Input.is_action_just_pressed("reload") or main.mobile_reload:
		_start_reload()
		main.mobile_reload = false
	if main.mobile_weapon:
		main.mobile_weapon = false
		switch_weapon((current_weapon + 1) % 3)

func _handle_look() -> void:
	if main.mobile_look_delta.length() > 0.0:
		var mobile_sensitivity: float = main.look_sensitivity * (0.62 if is_aiming else 0.78)
		yaw -= main.mobile_look_delta.x * mobile_sensitivity
		pitch = clampf(pitch - main.mobile_look_delta.y * mobile_sensitivity, -1.35, 1.35)
		rotation.y = yaw
		camera.rotation.x = pitch
		main.mobile_look_delta = Vector2.ZERO

func _handle_movement(delta: float) -> void:
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if main.mobile_move_vector.length() > 0.05:
		input_vec = main.mobile_move_vector
	is_aiming = Input.is_action_pressed("aim") or main.mobile_aim
	is_crouching = Input.is_action_pressed("crouch")
	var wants_sprint: bool = Input.is_action_pressed("sprint") or bool(main.mobile_sprint)
	is_sprinting = wants_sprint and input_vec.y < -0.35 and not is_aiming and not is_crouching
	var target_speed := WALK_SPEED
	if is_sprinting:
		target_speed = SPRINT_SPEED
	elif is_crouching or is_aiming:
		target_speed = CROUCH_SPEED if is_crouching else WALK_SPEED * 0.72
	target_speed *= speed_multiplier
	var direction := (transform.basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()
	var acceleration := 34.0 if is_on_floor() else 11.0
	velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("jump") or main.mobile_jump:
		velocity.y = JUMP_VELOCITY
		main.mobile_jump = false
	else:
		velocity.y = 0.0
	move_and_slide()
	global_position.x = clampf(global_position.x, -48.0, 48.0)
	global_position.z = clampf(global_position.z, -48.0, 48.0)

func _handle_weapon_pose(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	bob_time += delta * (7.0 if is_sprinting else 4.0 if horizontal_speed > 0.2 else 1.5)
	var bob_amount := 0.032 if is_sprinting else 0.016 if horizontal_speed > 0.2 else 0.004
	var bob := Vector3(sin(bob_time) * bob_amount, abs(cos(bob_time)) * bob_amount, 0)
	var aim_position := Vector3(0.02, -0.31, -1.2)
	var desired_base := aim_position if is_aiming else weapon_base_position
	if reloading:
		desired_base += Vector3(0.12, -0.32, 0.18)
	weapon.position = weapon.position.lerp(desired_base + bob + Vector3(damage_kick * 0.04, -damage_kick * 0.025, recoil * 0.12), delta * 12.0)
	weapon.rotation_degrees.x = -7.0 + recoil * 8.0 + damage_kick * 3.0
	weapon.rotation_degrees.z = lerpf(weapon.rotation_degrees.z, 38.0 if reloading else -3.0 if current_weapon == 2 else 0.0, delta * 10.0)
	var camera_height := 1.08 if is_crouching else 1.55
	camera.position = camera.position.lerp(Vector3(sin(bob_time * 11.0) * damage_kick * 0.015, camera_height + cos(bob_time * 9.0) * damage_kick * 0.012, 0), delta * 13.0)
	camera.fov = lerpf(camera.fov, 55.0 if is_aiming else 72.0 if is_sprinting else 68.0, delta * 10.0)

func _fire() -> void:
	if reloading or fire_cooldown > 0.0:
		return
	if ammo <= 0:
		_start_reload()
		return
	var spec: Dictionary = weapon_states[current_weapon]
	ammo -= 1
	weapon_states[current_weapon]["ammo"] = ammo
	main.shots += 1
	fire_cooldown = float(spec["fire_rate"]) / fire_rate_multiplier
	recoil = 1.25 if current_weapon == 1 else 1.0
	weapon_flash.visible = true
	if main.has_method("play_sound"):
		main.play_sound("scatter" if current_weapon == 1 else "shot", 0.92 + rng.randf_range(0.0, 0.16))
	if main.mobile_controls_visible:
		Input.vibrate_handheld(18)
	get_tree().create_timer(0.045).timeout.connect(func():
		if is_instance_valid(weapon_flash):
			weapon_flash.visible = false
	)
	var pellets := int(spec["pellets"])
	var pellet_damage := int(round(float(spec["damage"]) * damage_multiplier))
	var spread := float(spec["spread"]) * (0.45 if is_aiming else 1.0)
	var hit_any := false
	for pellet in range(pellets):
		if _fire_ray(pellet_damage, spread):
			hit_any = true
	if hit_any:
		main.hits += 1

func _fire_ray(damage: int, spread: float) -> bool:
	var basis := camera.global_transform.basis
	var direction := -basis.z
	direction = (direction + basis.x * rng.randf_range(-spread, spread) + basis.y * rng.randf_range(-spread, spread)).normalized()
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position + direction * 120.0)
	query.exclude = [self]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var collider: Object = hit["collider"]
	if collider.has_method("take_damage"):
		var hit_position: Vector3 = hit["position"]
		var critical: bool = hit_position.y > collider.global_position.y + 1.55 * collider.visual_root.scale.y
		collider.take_damage(int(round(float(damage) * (1.75 if critical else 1.0))), critical)
		return true
	return false

func _target_under_reticle() -> bool:
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_transform.basis.z * 65.0)
	query.exclude = [self]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit["collider"].has_method("take_damage")

func _start_reload() -> void:
	var spec: Dictionary = weapon_states[current_weapon]
	if reloading or ammo >= int(spec["mag"]) or reserve_ammo <= 0:
		return
	reloading = true
	reload_timer = float(spec["reload"])
	if main.has_method("play_sound"):
		main.play_sound("reload")

func _finish_reload() -> void:
	var spec: Dictionary = weapon_states[current_weapon]
	var needed := int(spec["mag"]) - ammo
	var loaded: int = mini(needed, reserve_ammo)
	ammo += loaded
	reserve_ammo -= loaded
	weapon_states[current_weapon]["ammo"] = ammo
	weapon_states[current_weapon]["reserve"] = reserve_ammo
	reloading = false

func switch_weapon(index: int) -> void:
	if index == current_weapon or index < 0 or index >= weapon_states.size() or main.paused:
		return
	_store_weapon_state()
	current_weapon = index
	reloading = false
	_load_weapon_state()
	_apply_weapon_pose()
	if main.has_method("play_sound"):
		main.play_sound("switch")

func _store_weapon_state() -> void:
	weapon_states[current_weapon]["ammo"] = ammo
	weapon_states[current_weapon]["reserve"] = reserve_ammo

func _load_weapon_state() -> void:
	var spec: Dictionary = weapon_states[current_weapon]
	ammo = int(spec["ammo"])
	reserve_ammo = int(spec["reserve"])

func _apply_weapon_pose() -> void:
	if current_weapon == 1:
		weapon.scale = Vector3(0.88, 0.8, 0.92)
		weapon_base_position = Vector3(0.55, -0.52, -1.32)
	elif current_weapon == 2:
		weapon.scale = Vector3(0.56, 0.62, 0.62)
		weapon_base_position = Vector3(0.48, -0.42, -1.18)
	else:
		weapon.scale = Vector3(0.72, 0.72, 0.72)
		weapon_base_position = Vector3(0.54, -0.5, -1.42)

func apply_pickup(kind: String) -> void:
	if kind == "health":
		if health < max_health:
			health = mini(max_health, health + 30)
		else:
			shield = mini(100, shield + 35)
	elif kind == "ammo":
		for index in range(weapon_states.size()):
			weapon_states[index]["reserve"] = mini(240, int(weapon_states[index]["reserve"]) + 18)
		_load_weapon_state()
	elif kind == "rapid":
		fire_rate_multiplier = minf(1.8, fire_rate_multiplier + 0.2)

func apply_upgrade(kind: String) -> void:
	if kind == "damage":
		damage_multiplier += 0.2
	elif kind == "speed":
		speed_multiplier += 0.12
	elif kind == "health":
		max_health += 25
		health = mini(max_health, health + 25)
	elif kind == "fire_rate":
		fire_rate_multiplier += 0.15
	elif kind == "magazine":
		for index in range(weapon_states.size()):
			weapon_states[index]["mag"] = int(weapon_states[index]["mag"]) + (2 if index == 1 else 6)
			weapon_states[index]["ammo"] = int(weapon_states[index]["mag"])
		_load_weapon_state()

func get_weapon_name() -> String:
	return String(weapon_states[current_weapon]["name"])

func get_mag_size() -> int:
	return int(weapon_states[current_weapon]["mag"])

func take_damage(amount: int) -> void:
	if main.game_over or hurt_cooldown > 0.0:
		return
	var remaining_damage := amount
	if shield > 0:
		var absorbed := mini(shield, remaining_damage)
		shield -= absorbed
		remaining_damage -= absorbed
	health = maxi(0, health - remaining_damage)
	hurt_cooldown = 0.62
	damage_kick = 0.22 if main.reduced_motion else 1.0
	if main.has_method("player_damaged"):
		main.player_damaged()
	if main.has_method("play_sound"):
		main.play_sound("hurt")
	if main.mobile_controls_visible:
		Input.vibrate_handheld(55)
	if health <= 0:
		main.player_died()
