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

## Mobile web controls

Mobile builds request landscape orientation and use an on-screen left joystick for movement, right-side drag aiming, plus Fire and Reload buttons. The viewport uses an expanding landscape layout so the controls remain usable across phone and tablet aspect ratios. `F2` toggles the touch-control overlay during desktop testing.

## Blender source kit

When Blender is available:

```sh
blender --background --python tools/generate_neon_mall.py
```

This creates `neon_mall_source.blend` and `neon_mall_kit.glb` in the current working directory. The Godot prototype intentionally remains procedural so gameplay can be tested without waiting for the authored asset pass.
