"""Generate the editable Neon Mall landmark, prop, alien, and weapon kit.

Run from the repository root:
  blender --background --python tools/generate_neon_mall.py
"""
import bpy
import math
import os
from mathutils import Vector

GREEN = (0.49, 1.0, 0.18, 1.0)
HOT = (0.76, 1.0, 0.5, 1.0)
DIM = (0.05, 0.28, 0.09, 1.0)
BLACK = (0.001, 0.006, 0.002, 1.0)


def material(name, color, emission=1.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = 1.0
    bsdf.inputs["Emission Color"].default_value = color
    bsdf.inputs["Emission Strength"].default_value = emission
    return mat


def cube(name, location, scale, mat, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    return obj


def cylinder(name, location, radius, depth, mat, vertices=8, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return obj


def sphere(name, location, scale, mat, segments=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=6, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    return obj


def stroke(name, start, end, width, mat):
    start = Vector(start)
    end = Vector(end)
    delta = end - start
    obj = cylinder(name, (start + end) * 0.5, width, delta.length, mat, 6)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = delta.to_track_quat("Z", "Y")
    return obj


def outline_box(name, location, half_size, mat, width=0.055):
    x, y, z = half_size
    px, py, pz = location
    for sy in (-1, 1):
        for sz in (-1, 1):
            cube(name, (px, py + sy * y, pz + sz * z), (x, width, width), mat)
    for sx in (-1, 1):
        for sz in (-1, 1):
            cube(name, (px + sx * x, py, pz + sz * z), (width, y, width), mat)
    for sx in (-1, 1):
        for sy in (-1, 1):
            cube(name, (px + sx * x, py + sy * y, pz), (width, width, z), mat)


def build_capitol(origin, black, green, dim):
    ox, oy, oz = origin
    cube("Capitol_Core", (ox, oy + 3, oz), (11, 3, 3.5), black)
    outline_box("Capitol_Ink", (ox, oy + 3, oz), (11, 3, 3.5), green, 0.08)
    for i in range(15):
        x = ox - 9 + i * 1.28
        cube("Capitol_Column", (x, oy + 3.9, oz - 3.8), (0.13, 2.4, 0.09), green)
    sphere("Capitol_Dome", (ox, oy + 8.3, oz), (5, 2.4, 3.25), black)
    for i in range(7):
        x = -4.3 + i * 1.43
        stroke("Dome_Rib", (ox + x, oy + 7.15, oz - 2.2), (ox + x * 0.25, oy + 10.25, oz - 1.15), 0.07, green)
    cylinder("Capitol_Spire", (ox, oy + 11.3, oz), 0.12, 4, green, 6)
    for side in (-1, 1):
        cube("Capitol_Wing", (ox + side * 14, oy + 2.65, oz + 0.5), (3, 2.65, 3), black)
        outline_box("Capitol_Wing_Ink", (ox + side * 14, oy + 2.65, oz + 0.5), (3, 2.65, 3), green)
    for step in range(5):
        cube("Capitol_Step", (ox, oy + 0.12 + step * 0.12, oz - 5.6 + step * 0.35), (14.5 - step * 0.8, 0.04, 0.09), green)


def build_monument(origin, black, green, dim):
    ox, oy, oz = origin
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=2.1, radius2=0.72, depth=24, location=(ox, oy + 12.2, oz), rotation=(0, math.pi / 4, 0))
    bpy.context.object.name = "Washington_Monument_Core"
    bpy.context.object.data.materials.append(black)
    for side in (-1, 1):
        stroke("Monument_Edge", (ox + side * 2.1, oy + 0.2, oz), (ox + side * 0.7, oy + 24.3, oz), 0.09, green)
        stroke("Monument_Back_Edge", (ox, oy + 0.2, oz + side * 2.1), (ox, oy + 24.3, oz + side * 0.7), 0.065, dim)
        stroke("Monument_Point", (ox + side * 0.7, oy + 24.2, oz), (ox, oy + 27, oz), 0.08, green)
    for i in range(18):
        angle = i / 18 * math.tau
        cylinder("Monument_Flagpole", (ox + math.cos(angle) * 6.2, oy + 1.6, oz + math.sin(angle) * 6.2), 0.035, 3.2, dim, 6)


def build_lincoln(origin, black, green, dim):
    ox, oy, oz = origin
    cube("Lincoln_Core", (ox, oy + 4.2, oz), (12, 4.1, 3.5), black)
    outline_box("Lincoln_Ink", (ox, oy + 4.2, oz), (12.2, 4.25, 3.6), green, 0.07)
    cube("Lincoln_Roof", (ox, oy + 8.7, oz - 0.2), (13.5, 0.18, 4.25), green)
    for i in range(12):
        x = ox - 10.5 + i * 1.9
        cube("Lincoln_Column", (x, oy + 4.2, oz - 3.75), (0.15, 3.35, 0.14), green)
    for step in range(7):
        cube("Lincoln_Stair", (ox, oy + 0.1 + step * 0.1, oz - 5.7 + step * 0.42), (14.5 - step * 0.7, 0.035, 0.08), green)


def build_alien(name, origin, scale, black, green, hot):
    ox, oy, oz = origin
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    parts = []
    parts.append(sphere(name + "_Head", (ox, oy + 1.95 * scale, oz), (0.48 * scale, 0.58 * scale, 0.42 * scale), black))
    parts.append(cylinder(name + "_Body", (ox, oy + 1.0 * scale, oz), 0.4 * scale, 1.25 * scale, black, 8))
    for side in (-1, 1):
        parts.append(cube(name + "_Eye", (ox + side * 0.2 * scale, oy + 2.0 * scale, oz - 0.4 * scale), (0.15 * scale, 0.055 * scale, 0.04 * scale), hot, rotation=(0, 0, side * 0.16)))
        parts.append(stroke(name + "_Arm", (ox + side * 0.38 * scale, oy + 1.45 * scale, oz), (ox + side * 0.72 * scale, oy + 0.7 * scale, oz), 0.07 * scale, green))
        parts.append(stroke(name + "_Leg", (ox + side * 0.18 * scale, oy + 0.55 * scale, oz), (ox + side * 0.3 * scale, oy, oz - 0.12 * scale), 0.08 * scale, green))
        parts.append(stroke(name + "_Antenna", (ox + side * 0.18 * scale, oy + 2.45 * scale, oz), (ox + side * 0.35 * scale, oy + 2.8 * scale, oz), 0.035 * scale, green))
    parts.append(cube(name + "_Rifle", (ox, oy + 1.05 * scale, oz - 0.5 * scale), (0.7 * scale, 0.04 * scale, 0.04 * scale), green, rotation=(0, 0, -0.07)))
    for part in parts:
        part.parent = root


def build_weapon(origin, black, green, dim):
    ox, oy, oz = origin
    cube("Viewmodel_Receiver", (ox, oy, oz), (0.35, 0.22, 1.15), black, rotation=(0, 0, -0.04))
    outline_box("Viewmodel_Ink", (ox, oy, oz), (0.37, 0.24, 1.17), green, 0.035)
    cube("Viewmodel_Scope", (ox, oy + 0.34, oz - 0.2), (0.2, 0.16, 0.42), black)
    outline_box("Scope_Ink", (ox, oy + 0.34, oz - 0.2), (0.22, 0.18, 0.44), green, 0.025)
    cube("Viewmodel_Grip", (ox, oy - 0.38, oz + 0.4), (0.17, 0.42, 0.22), black, rotation=(-0.22, 0, 0))
    for i in range(5):
        cube("Barrel_Rib", (ox, oy + 0.2, oz - 0.55 - i * 0.18), (0.25, 0.025, 0.025), dim)


def build_scattergun(origin, black, green, hot):
    ox, oy, oz = origin
    cube("Scatter_Receiver", (ox, oy, oz), (0.42, 0.26, 0.72), black)
    outline_box("Scatter_Ink", (ox, oy, oz), (0.45, 0.29, 0.75), green, 0.035)
    for side in (-1, 1):
        cube("Scatter_Barrel", (ox + side * 0.22, oy + 0.08, oz - 0.86), (0.13, 0.13, 0.62), black)
        outline_box("Scatter_Barrel_Ink", (ox + side * 0.22, oy + 0.08, oz - 0.86), (0.15, 0.15, 0.64), hot, 0.025)
    for i in range(5):
        cube("Scatter_Pump_Rib", (ox, oy - 0.11, oz - 0.28 - i * 0.11), (0.38, 0.02, 0.02), green)


def build_pistol(origin, black, green, hot):
    ox, oy, oz = origin
    cube("Pistol_Slide", (ox, oy + 0.08, oz - 0.1), (0.27, 0.2, 0.58), black)
    outline_box("Pistol_Ink", (ox, oy + 0.08, oz - 0.1), (0.29, 0.22, 0.6), hot, 0.03)
    cube("Pistol_Grip", (ox, oy - 0.37, oz + 0.28), (0.2, 0.42, 0.22), black, rotation=(-0.22, 0, 0))
    outline_box("Pistol_Grip_Ink", (ox, oy - 0.37, oz + 0.28), (0.22, 0.44, 0.24), green, 0.025)


def build():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    black = material("INK_BLACK", BLACK, 0.0)
    green = material("NEON_GREEN_INK", GREEN, 4.0)
    hot = material("NEON_HOT_INK", HOT, 6.0)
    dim = material("NEON_DIM_INK", DIM, 2.0)

    cube("Mall_Ground", (0, -0.5, 0), (55, 0.5, 55), black)
    cube("Reflecting_Pool", (0, 0, -5), (4, 0.04, 41), black)
    outline_box("Reflecting_Pool_Ink", (0, 0.06, -5), (4.2, 0.08, 41), green)
    for x in (-18, -9, 9, 18):
        cube("Mall_Path_Ink", (x, 0.03, 0), (0.06, 0.02, 46), green)
    build_capitol((0, 0, -45), black, green, dim)
    build_monument((0, 0, 24), black, green, dim)
    build_lincoln((0, 0, 48), black, green, dim)

    for i in range(12):
        angle = i * 2.399
        radius = 15 + (i * 13) % 25
        location = (math.cos(angle) * radius, 0.9, math.sin(angle) * radius)
        cube("Wreckage_Core", location, (1.4, 0.9, 0.75), black, rotation=(0, angle, 0))
        outline_box("Wreckage_Ink", location, (1.45, 0.95, 0.8), dim)
    for x in (-31, -24, 24, 31):
        for z in (-36, -18, 18, 36):
            cylinder("Mall_Lamp", (x, 3, z), 0.07, 6, green, 6)
            cube("Lamp_Glow", (x, 6.1, z), (0.38, 0.09, 0.38), hot)

    # Asset lineup outside the arena for easy Blender editing/export reuse.
    build_alien("Alien_Scout", (-12, 0, 57), 0.72, black, green, hot)
    build_alien("Alien_Rifle", (-4, 0, 57), 1.0, black, green, hot)
    build_alien("Alien_Bruiser", (5, 0, 57), 1.65, black, green, hot)
    build_alien("Alien_Elite", (16, 0, 57), 2.05, black, hot, hot)
    build_weapon((25, 1.2, 57), black, green, dim)
    build_scattergun((31, 1.2, 57), black, green, hot)
    build_pistol((36, 1.2, 57), black, green, hot)

    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(repo_root, "neon_mall_source.blend"))
    bpy.ops.export_scene.gltf(filepath=os.path.join(repo_root, "neon_mall_kit.glb"), export_format="GLB", export_apply=True)


if __name__ == "__main__":
    build()
