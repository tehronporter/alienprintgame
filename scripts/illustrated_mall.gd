extends Node3D
## Illustrated cutouts inhabit a real navigable arena; all pen marks share one mesh.
const Art = preload("res://scripts/ink_art.gd")
const INK := Color("#99ff60")
const DIM := Color("#39852e")
var pen := SurfaceTool.new()
var rng := RandomNumberGenerator.new()
var game: Node

func build(owner_game: Node) -> void:
	game = owner_game
	rng.seed = 88127
	pen.begin(Mesh.PRIMITIVE_TRIANGLES)
	game._make_box("MallGround", Vector3(0, -0.6, 0), Vector3(110, 1, 110), Color("#010401"), 0.1)
	var capitol := Art.sprite("capitol", 23.0)
	capitol.name = "IllustratedCapitol"
	capitol.position += Vector3(0, 0, -47)
	capitol.scale.x = 1.6
	add_child(capitol)
	game._make_box("CapitolFoundation", Vector3(0, 1, -49), Vector3(38, 2, 4), Color("#010401"), 0.1)
	# Short pool leaves a broad, playable promenade in the opening view.
	game._make_visual_box("ReflectingPool", Vector3(0, -0.06, -25), Vector3(7, 0.04, 24), Color("#020a03"), 0.1)
	for side in [-1.0, 1.0]:
		stroke(Vector3(side * 3.7, 0, -37), Vector3(side * 3.7, 0, -13), 0.035)
		for lane in [8.5, 15.0]:
			for section in range(18):
				var z := -43.0 + section * 5.0
				stroke(Vector3(side * lane, 0, z), Vector3(side * lane + rng.randf_range(-0.07, 0.07), 0, z + 4.9), 0.028)
		for i in range(11):
			var tree := Art.sprite("tree", 8.0 + rng.randf() * 5.0, true)
			tree.name = "InkTree"
			tree.position += Vector3(side * (21 + rng.randf() * 7), 0, -41 + i * 8)
			tree.flip_h = i % 2 == 0
			add_child(tree)
		for i in range(7):
			lamp(Vector3(side * 12.8, 0, -37 + i * 12))
			flag(Vector3(side * 17.2, 0, -35 + i * 12), side)
		for i in range(5):
			bench(Vector3(side * 10.8, 0, -29 + i * 15))
	monument(Vector3(24, 0, -30))
	memorial(Vector3(0, 0, 47))
	for i in range(260):
		var a := Vector3(rng.randf_range(-47, 47), 0.015, rng.randf_range(-44, 45))
		if absf(a.x) < 4 and a.z < -12: continue
		for j in range(rng.randi_range(3, 8)):
			var b := a + Vector3(rng.randf_range(-0.65, 0.65), 0, rng.randf_range(0.4, 1.8))
			stroke(a, b, 0.017, DIM if i % 3 == 0 else INK)
			if j == 2: stroke(a, a + Vector3(0.8, 0, -0.3), 0.014, DIM)
			a = b
	for i in range(200):
		var p := Vector3(rng.randf_range(-47, 47), 0.01, rng.randf_range(-43, 44))
		if absf(p.x) < 4 and p.z < -12: continue
		if absf(p.x) > 16:
			for blade in range(3):
				stroke(p + Vector3(blade * 0.12, 0, 0), p + Vector3(blade * 0.15 - 0.1, rng.randf_range(0.15, 0.4), 0), 0.015, DIM)
		else:
			ring(p, Vector2(0.2, 0.1), 7, 0.015, false, DIM)
	for i in range(90):
		var p := Vector3(rng.randf_range(-3.4, 3.4), 0, rng.randf_range(-36, -13))
		stroke(p, p + Vector3(rng.randf_range(0.1, 1.1), 0, 0.04), 0.018, DIM)
	ufo(Vector3(-14, 16, -30), 2.6)
	ufo(Vector3(18, 20, -43), 1.8)
	# Low cover keeps aliens readable along the promenade.
	for side in [-1.0, 1.0]:
		for z in [-18.0, 9.0, 30.0]:
			game._make_box("LowCover", Vector3(side * 15.5, 0.35, z), Vector3(2.2, 0.7, 1.2), Color("#010401"), 0.1)
			for y in [0.05, 0.7]:
				stroke(Vector3(side * 15.5 - 1.1, y, z - 0.6), Vector3(side * 15.5 + 1.1, y, z - 0.6), 0.035)
	game._make_hotdog_cart(Vector3(-12, 0, 15))
	drawn_car(Vector3(15, 0, 5))
	game._make_subway_entrance(Vector3(36, 0, 0))
	street_details()
	var mesh := MeshInstance3D.new()
	mesh.name = "BatchedHandDrawnDetails"
	mesh.mesh = pen.commit()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = material
	add_child(mesh)

func stroke(a: Vector3, b: Vector3, width := 0.025, color := INK) -> void:
	width *= 2.0
	var direction := (b - a).normalized()
	var across := direction.cross(Vector3.UP)
	if across.length_squared() < 0.01: across = direction.cross(Vector3.FORWARD)
	across = across.normalized() * width * 0.5
	var other := direction.cross(across).normalized() * width * 0.5
	pen.set_color(color)
	for offset in [across, other]:
		for vertex in [a - offset, a + offset, b + offset, a - offset, b + offset, b - offset]:
			pen.add_vertex(vertex)

func ring(p: Vector3, radius: Vector2, count := 24, width := 0.025, upright := true, color := INK) -> void:
	var points: Array[Vector3] = []
	for i in range(count + 1):
		var t := TAU * i / count
		var wobble := 1 + sin(t * 7) * 0.025
		var x := cos(t) * radius.x * wobble
		var y := sin(t) * radius.y * wobble
		points.append(p + (Vector3(x, y, 0) if upright else Vector3(x, 0, y)))
	for i in range(count): stroke(points[i], points[i + 1], width, color)

func lamp(p: Vector3) -> void:
	for side in [-1.0, 1.0]:
		stroke(p + Vector3(side * 0.08, 0, 0), p + Vector3(side * 0.045, 5.3, 0), 0.035)
		stroke(p + Vector3(side * 0.21, 5.3, 0), p + Vector3(side * 0.35, 6.25, 0), 0.038)
		stroke(p + Vector3(side * 0.35, 6.25, 0), p + Vector3(0, 6.65, 0), 0.035)
		stroke(p + Vector3(side * 0.12, 5.45, 0), p + Vector3(side * 0.18, 6.2, 0), 0.023)
	for y in [0.12, 0.25, 0.6, 4.9, 5.25, 6.25]:
		ring(p + Vector3(0, y, 0), Vector2(0.22 if y < 1 else 0.3, 0.08), 16, 0.03)
	ring(p + Vector3(0, 6.67, 0), Vector2(0.07, 0.1), 12, 0.03)

func flag(p: Vector3, side: float) -> void:
	stroke(p, p + Vector3(0, 7, 0), 0.035)
	for stripe in range(8):
		var last := p + Vector3(0, 6.9 - stripe * 0.15, 0)
		for section in range(10):
			var x := (section + 1) * 0.18
			var next := p + Vector3(x * -side, 6.9 - stripe * 0.15 + sin(x * 3) * 0.15, 0)
			stroke(last, next, 0.022)
			last = next
	stroke(p + Vector3(-side * 1.8, 5.73, 0), p + Vector3(-side * 1.8, 6.78, 0), 0.03)

func bench(p: Vector3) -> void:
	for y in [0.5, 0.8, 1.0, 1.2]:
		stroke(p + Vector3(-1.3, y, 0), p + Vector3(1.3, y + 0.025, 0), 0.045)
	for side in [-1.0, 1.0]:
		stroke(p + Vector3(side, 0, 0), p + Vector3(side, 1.25, 0), 0.05)
		stroke(p + Vector3(side, 0.5, 0), p + Vector3(side, 0.5, 0.6), 0.05)
		stroke(p + Vector3(side, 0.5, 0.6), p + Vector3(side, 0, 0.65), 0.05)

func monument(p: Vector3) -> void:
	game._make_box("MonumentPlinth", p + Vector3(0, 0.3, 0), Vector3(4, 0.6, 4), Color("#010401"), 0.1)
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			stroke(p + Vector3(x, 0, z), p + Vector3(x * 0.6, 23, z * 0.6), 0.065)
			stroke(p + Vector3(x * 0.6, 23, z * 0.6), p + Vector3(0, 26, 0), 0.055)
	for i in range(30):
		var y := i * 0.74
		stroke(p + Vector3(-0.9, y, -0.95), p + Vector3(0.9, y + 0.03, -0.95), 0.012, DIM)

func memorial(p: Vector3) -> void:
	game._make_lincoln_memorial(p)
	for i in range(12):
		var x := -10.5 + i * 1.9
		for offset in [-0.2, 0.2]:
			stroke(p + Vector3(x + offset, 1, -3.92), p + Vector3(x + offset * 0.8, 7.6, -3.92), 0.035)

func ufo(p: Vector3, radius: float) -> void:
	ring(p, Vector2(radius, radius * 0.24), 40, 0.045)
	ring(p + Vector3(0, radius * 0.27, 0), Vector2(radius * 0.48, radius * 0.35), 28, 0.035)
	for i in range(5):
		ring(p + Vector3(-radius * 0.7 + i * radius * 0.35, 0, 0), Vector2(0.07, 0.06), 8, 0.03)
	for i in range(4):
		var a := p + Vector3((i - 1.5) * 0.35, -0.7, 0)
		stroke(a, a + Vector3((i - 1.5) * 0.4, -2.5, 0), 0.02, DIM)

func drawn_car(p: Vector3) -> void:
	game._make_box("CarCover", p + Vector3(0, 0.6, 0), Vector3(4.4, 1.2, 1.7), Color("#010401"), 0.1)
	var contour := [Vector3(-2.4, 0.5, 0), Vector3(-2.4, 1.0, 0), Vector3(-1.3, 1.15, 0), Vector3(-0.7, 1.9, 0), Vector3(0.9, 1.85, 0), Vector3(1.5, 1.15, 0), Vector3(2.4, 1.0, 0), Vector3(2.4, 0.5, 0)]
	for side in [-1.0, 1.0]:
		for i in range(contour.size() - 1):
			stroke(p + contour[i] + Vector3(0, 0, side * 0.92), p + contour[i + 1] + Vector3(0, 0, side * 0.92), 0.028)
		for x in [-1.5, 1.5]:
			ring(p + Vector3(x, 0.45, side * 0.98), Vector2(0.46, 0.46), 22, 0.03)
			ring(p + Vector3(x, 0.45, side * 0.99), Vector2(0.28, 0.28), 16, 0.02)
			for spoke in range(8):
				var t := spoke * TAU / 8
				stroke(p + Vector3(x, 0.45, side * 0.99), p + Vector3(x + cos(t) * 0.28, 0.45 + sin(t) * 0.28, side * 0.99), 0.015)
		stroke(p + Vector3(0.2, 0.6, side * 0.94), p + Vector3(0.2, 1.8, side * 0.94), 0.02)
		stroke(p + Vector3(-1.1, 1.2, side * 0.94), p + Vector3(1.4, 1.2, side * 0.94), 0.02)
	for v in contour: stroke(p + v + Vector3(0, 0, -0.92), p + v + Vector3(0, 0, 0.92), 0.023)

func street_details() -> void:
	# Broken paving joints, paper scraps and hatch marks give the foreground scale.
	for row in range(24):
		var z := -10.0 + row * 2.4
		for col in range(6):
			var x := -8.0 + col * 2.8
			stroke(Vector3(x + 0.1, 0.018, z), Vector3(x + 2.5, 0.018, z + rng.randf_range(-0.08, 0.08)), 0.011, DIM)
			if (row + col) % 3 == 0: stroke(Vector3(x, 0.019, z), Vector3(x + 0.06, 0.019, z + 1.5), 0.012, DIM)
	for i in range(42):
		var p := Vector3(rng.randf_range(-18, 18), 0.025, rng.randf_range(-10, 42))
		var corners := [p, p + Vector3(0.55, 0, 0.12), p + Vector3(0.4, 0, 0.75), p + Vector3(-0.14, 0, 0.6), p]
		for edge in range(4): stroke(corners[edge], corners[edge + 1], 0.018)
		for line in range(3): stroke(p + Vector3(0.06, 0, 0.18 + line * 0.13), p + Vector3(0.35, 0, 0.24 + line * 0.13), 0.014, DIM)
	for side in [-1.0, 1.0]:
		for i in range(6):
			var p := Vector3(side * 19, 0, -25 + i * 11)
			for y in [0.1, 0.85]: ring(p + Vector3(0, y, 0), Vector2(0.8, 0.5), 22, 0.025, false)
			for rib in range(12):
				var t := TAU * rib / 12
				stroke(p + Vector3(cos(t) * 0.8, 0.1, sin(t) * 0.5), p + Vector3(cos(t) * 0.8, 0.85, sin(t) * 0.5), 0.018)
			var bush := Art.sprite("tree", 1.9, true)
			bush.position += p + Vector3(0, 0.55, 0)
			add_child(bush)
		# Layered city skyline beyond the park trees.
		for block in range(6):
			var p := Vector3(side * (35 + block * 2), 0, -41 + block * 14)
			var h := 7.0 + block % 3 * 2
			for x in [-2.5, 2.5]: stroke(p + Vector3(x, 0, 0), p + Vector3(x, h, 0), 0.024, DIM)
			stroke(p + Vector3(-2.5, h, 0), p + Vector3(2.5, h, 0), 0.03, DIM)
			for floor in range(3):
				for window in range(4):
					var q := p + Vector3(-1.8 + window * 1.1, 2 + floor * 1.8, 0)
					stroke(q, q + Vector3(0, 0.75, 0), 0.03, DIM)
	var sign := Label3D.new()
	sign.text = "HOT DOGS"
	sign.font = preload("res://assets/fonts/Kalam-Regular.ttf")
	sign.font_size = 64
	sign.pixel_size = 0.008
	sign.modulate = INK
	sign.position = Vector3(-12, 1.2, 15.88)
	add_child(sign)
