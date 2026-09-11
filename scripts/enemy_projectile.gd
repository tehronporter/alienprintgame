extends Node3D

var main: Node
var active := false
var direction := Vector3.ZERO
var speed := 15.0
var damage := 8
var life := 0.0

func _ready() -> void:
	var core := MeshInstance3D.new()
	var core_mesh := BoxMesh.new()
	core_mesh.size = Vector3(0.16, 0.16, 0.75)
	core.mesh = core_mesh
	core.material_override = _material(Color("#c4ff82"), 4.0)
	add_child(core)
	for side in [-1.0, 1.0]:
		var scratch := MeshInstance3D.new()
		var scratch_mesh := BoxMesh.new()
		scratch_mesh.size = Vector3(0.04, 0.04, 1.2)
		scratch.mesh = scratch_mesh
		scratch.position.x = side * 0.18
		scratch.material_override = _material(Color("#7dff35"), 2.2)
		add_child(scratch)

func _material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func activate(start: Vector3, target: Vector3, projectile_damage: int, projectile_speed := 15.0) -> void:
	global_position = start
	direction = start.direction_to(target)
	damage = projectile_damage
	speed = projectile_speed
	life = 4.0
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	look_at(target, Vector3.UP)

func deactivate() -> void:
	active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func _process(delta: float) -> void:
	if not active or main.paused or main.game_over:
		return
	life -= delta
	global_position += direction * speed * delta
	rotation.z += delta * 7.0
	if global_position.distance_to(main.player.global_position + Vector3(0, 1.0, 0)) < 0.9:
		main.player.take_damage(damage)
		deactivate()
	elif life <= 0.0 or absf(global_position.x) > 60.0 or absf(global_position.z) > 60.0:
		deactivate()
