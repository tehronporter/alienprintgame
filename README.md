# Neon Mall

An endless first-person alien shooter prototype set on a hand-drawn neon National Mall.

## Run locally

Requires Godot 4.x.

```sh
godot --editor project.godot
```

Then press Play. The project is configured for the Compatibility renderer and Web export.

## Controls

- `WASD` move
- Mouse aim
- Left mouse button fire
- `R` reload
- `Esc` pause/release mouse
- `Enter` deploy from the title screen
- Click after death to redeploy

## Mac touchpad controls

The title screen and pause screen include **Control Calibration**. Enable **Touchpad Mode** for a slower, steadier look multiplier, then tune the sensitivity slider until camera movement feels comfortable. The setting is saved per computer in Godot's `user://` preferences and does not affect other players or devices.

## Blender source kit

When Blender is available:

```sh
blender --background --python tools/generate_neon_mall.py
```

This creates `neon_mall_source.blend` and `neon_mall_kit.glb` in the current working directory. The Godot prototype intentionally remains procedural so gameplay can be tested without waiting for the authored asset pass.
