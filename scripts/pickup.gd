extends Node3D

const GREEN := Color("#7dff35")
const HOT := Color("#c4ff82")

var main: Node
var active := false
var pickup_type := "ammo"
var base_y := 0.6
var motion := 0.0

func _ready() -> void:
	var core := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.65, 0.65, 0.65)
	core.mesh = mesh
	core.material_override = _material(Color("#020904"), 0.1)
	add_child(core)
	for axis in range(3):
		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.32
		ring_mesh.outer_radius = 0.39
		ring_mesh.rings = 8
		ring_mesh.ring_segments = 6
		ring.mesh = ring_mesh
		ring.rotation = Vector3(PI * 0.5 if axis == 1 else 0, PI * 0.5 if axis == 2 else 0, 0)
		ring.material_override = _material(GREEN, 2.2)
		add_child(ring)

func _material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func activate(kind: String, spawn_position: Vector3) -> void:
	pickup_type = kind
	global_position = spawn_position + Vector3(0, base_y, 0)
	motion = 0.0
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	var pickup_scale := 1.2 if kind == "rapid" else 1.0
	scale = Vector3.ONE * pickup_scale

func deactivate() -> void:
	active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func _process(delta: float) -> void:
	if not active or main.paused or main.game_over:
		return
	motion += delta
	rotation.y += delta * 1.8
	position.y = base_y + sin(motion * 3.0) * 0.18
	if global_position.distance_to(main.player.global_position + Vector3(0, 0.8, 0)) < 1.4:
		main.player.apply_pickup(pickup_type)
		main.pickup_collected(pickup_type)
		deactivate()
