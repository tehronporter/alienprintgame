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
- Right mouse button aim down sights
- `Shift` sprint
- `Space` jump
- `C` crouch
- `1`, `2`, `3` or mouse wheel switch weapons
- `R` reload
- `Esc` pause/release mouse
- `Enter` deploy from the title screen
- Click after death to redeploy

Combat begins with seven enemies already active. The rifle, scattergun, and pistol use separate magazines and reserves. Weak-point hits deal critical damage. Kills build a short streak multiplier; enemies drop pooled health, ammo, and rapid-fire pickups. Every two minutes, play pauses for a three-option field-mod choice. Enemy health, speed, scale, active cap, ranged pressure, bruiser frequency, and elite events increase with survival time.

## Mac touchpad controls

The title screen and pause screen include **Control Calibration**. Enable **Touchpad Mode** for a slower, steadier look multiplier, then tune the sensitivity slider until camera movement feels comfortable. The setting is saved per computer in Godot's `user://` preferences and does not affect other players or devices.

## Mobile web controls

Mobile builds request landscape orientation and use an on-screen left joystick, right-side drag aiming, dedicated Fire/Reload/Jump/Swap controls, and toggles for Sprint and Aim. Optional auto-fire engages when an alien is centered, following the familiar mobile-shooter pattern. Portrait mode displays a rotate-device gate. Controls scale to phone/tablet height, respect browser safe areas, and cap active enemies at 28 for Web performance. `F2` toggles the touch-control overlay during desktop testing.

## Blender source kit

When Blender is available:

```sh
blender --background --python tools/generate_neon_mall.py
```

This creates `neon_mall_source.blend` and `neon_mall_kit.glb` in the repository root. The source kit includes the Mall blockout, Capitol, Washington Monument, Lincoln Memorial, props, four alien scales, and distinct rifle/scattergun/pistol viewmodels. Godot remains procedural so the playable build and editable Blender source stay independently testable.

The current visual pass adds layered city silhouettes, smoke plumes, invasion scratches, checkpoints, newspapers, landmark hatching, weapon-specific silhouettes, enemy-class armor profiles, animated screen grain, and a hand-inked radar/compass without shipping the large reference files.

## Verification

```sh
godot --headless --path . --script tests/combat_smoke.gd
godot --headless --path . --script tests/gameplay_systems_smoke.gd
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server 8060 -d build/web
```

The export excludes the 4K reference set and `.blend` source from the runtime package; the current PCK is under 1 MB.
