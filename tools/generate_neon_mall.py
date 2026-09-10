"""Run with Blender in background mode to generate the reusable source kit.

Example:
  blender --background --python tools/generate_neon_mall.py

The Godot prototype is intentionally procedural so gameplay can be tested
without waiting for authored assets. This file provides the Blender handoff.
"""
import bpy
import math
from mathutils import Vector

GREEN = (0.49, 1.0, 0.18, 1.0)
BLACK = (0.0, 0.0, 0.0, 1.0)

def material(name, color, emission=1.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color[:3], 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color[:3], 1.0)
    bsdf.inputs["Emission Color"].default_value = (*color[:3], 1.0)
    bsdf.inputs["Emission Strength"].default_value = emission
    return mat

def cube(name, location, scale, mat):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    return obj

def cylinder(name, location, radius, depth, mat, vertices=8):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return obj

def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)

def build():
    clear()
    black = material("INK_BLACK", BLACK, 0.0)
    green = material("NEON_GREEN_INK", GREEN, 4.0)
    ground = cube("Mall_Ground", (0, -0.5, 0), (55, 0.5, 55), black)
    for x in (-18, -9, 9, 18):
        cube("Path_Line", (x, 0.03, 0), (0.1, 0.03, 46), green)
    for z in (-28, -12, 12, 28):
        cube("Cross_Path_Line", (0, 0.03, z), (36, 0.03, 0.1), green)
    # Lincoln Memorial blockout and columns.
    cube("Lincoln_Memorial", (0, 4.0, -47), (6.5, 4.5, 2.5), black)
    for i in range(12):
        x = -5.2 + i * 0.95
        cube("Lincoln_Column", (x, 4.4, -49.8), (0.18, 3.2, 0.14), green)
    # Washington Monument silhouette.
    cylinder("Washington_Monument", (0, 13, 38), 2.0, 26, green, 4)
    # Wreckage and lamps.
    for i in range(14):
        angle = i * 2.399
        radius = 15 + (i * 13) % 25
        cube("Wreckage", (math.cos(angle) * radius, 1, math.sin(angle) * radius), (1.4, 0.9, 0.75), green)
    for x in (-31, -24, 24, 31):
        for z in (-36, -18, 18, 36):
            cylinder("Mall_Lamp", (x, 3, z), 0.09, 6, green, 6)
            cube("Lamp_Glow", (x, 6.1, z), (0.38, 0.09, 0.38), green)
    bpy.ops.wm.save_as_mainfile(filepath="neon_mall_source.blend")
    bpy.ops.export_scene.gltf(filepath="neon_mall_kit.glb", export_format="GLB")

if __name__ == "__main__":
    build()
