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
var weapon: MeshInstance3D

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
	camera.current = true
	add_child(camera)
	weapon = MeshInstance3D.new()
	var gun := BoxMesh.new()
	gun.size = Vector3(0.22, 0.18, 0.9)
	weapon.mesh = gun
	weapon.position = Vector3(0.34, -0.32, -0.72)
	weapon.rotation_degrees = Vector3(-7, 0, 0)
	weapon.material_override = _material(Color("#7dff35"), 2.2)
	camera.add_child(weapon)

func _material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and main.game_started and not main.game_over and not main.paused:
		yaw -= event.relative.x * 0.0025
		pitch = clamp(pitch - event.relative.y * 0.0025, -1.35, 1.35)
		rotation.y = yaw
		camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	if not main.game_started or main.game_over or main.paused:
		return
	if fire_cooldown > 0.0:
		fire_cooldown -= delta
	if reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
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
	if Input.is_action_pressed("fire"):
		_fire()
	if Input.is_action_just_pressed("reload"):
		_start_reload()

func _fire() -> void:
	if reloading or fire_cooldown > 0.0:
		return
	if ammo <= 0:
		_start_reload()
		return
	ammo -= 1
	main.shots += 1
	fire_cooldown = FIRE_RATE
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_transform.basis.z * 100.0)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.has_method("take_damage"):
		hit.collider.take_damage(25)
		main.hits += 1
	weapon.position.z = -0.82
	get_tree().create_timer(0.045).timeout.connect(func(): weapon.position.z = -0.72)

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
	if main.game_over:
		return
	health = max(0, health - amount)
	if health <= 0:
		main.player_died()
