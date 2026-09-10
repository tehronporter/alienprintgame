# Neon Mall Visual Bible

## North star

The game should look like a child drew an alien invasion over black construction paper with one fluorescent green marker. Silhouette and composition matter more than polish. Imperfect spacing, crooked parallel lines, oversized eyes, blunt geometry, and visible construction marks are features of the style.

## Palette and rendering

- Background and solid masses: near-black `#010301` and ink-black `#020904`.
- Primary line: neon green `#7DFF35`.
- Highlight, eyes, muzzle flashes, and hit flashes: hot green `#C4FF82`.
- Secondary construction lines: dark green `#164D20`.
- Materials are unshaded emission so the green stays graphic in WebGL.
- Use dark cores with bright edge strokes. Avoid large green filled surfaces except for brief combat flashes or very close alien limbs.
- Screen treatment uses a green vignette, scanline variation, corner registration marks, and damage-frame scratches.

## Shape language

- Architecture: recognizable landmark silhouette first, then repeated childlike marks—columns, steps, ribs, windows, flagpoles, cracks.
- Nature: clustered low-poly dark canopy masses with short horizontal leaf scratches and crooked trunks.
- Aliens: bulbous dark heads, two slanted glowing eyes, long uneven limbs, broad shoulder marks, and a rifle crossing the torso.
- Weapon: dense lower-right dark mass with a bright perimeter, scope box, top ribs, barrel cage, grip, and visible hands.
- Effects: short straight ink shards rather than smoke particles or realistic sparks.

## Composition targets

- The Capitol anchors the starting sightline; the monument anchors the reverse view.
- The Reflecting Pool and four long path strokes create strong perspective toward the landmarks.
- Foreground wreckage and street furniture frame the view without blocking the center crosshair.
- At least three depth layers should be visible: foreground weapon/cover, middle-distance enemies/trees, distant landmark/UFO.
- HUD information stays around the perimeter so the center remains a clear shooting lane.

## Performance budget

- Compatibility renderer, no required texture maps, no real-time shadows, and no transparent particle systems.
- Reuse a fixed pool of 48 enemies; desktop active cap 42, mobile cap 28.
- Effects self-delete after 0.42 seconds.
- Runtime package excludes the 4K reference PNGs and Blender source.
- Prefer 6–10 segment rounded meshes and straight ink strokes over dense curves.

## Completed production phases

1. Visual bible and asset checklist — this document and the supplied reference set.
2. Ink rendering system — dark cores, unshaded emission strokes, screen treatment, and custom drawn HUD.
3. DC environment — Reflecting Pool, detailed Capitol, tapered monument, paths, trees, flags, lamps, subway entrance, cart, wreckage, cars, and UFOs.
4. Hero assets — rifle viewmodel and four alien gameplay silhouettes in Godot and Blender.
5. Combat effects — muzzle flash, recoil, hit flash, hitmarker, damage frame, camera/weapon kick, attack tell, and death shards.
6. HUD and flow — start/pause/death states, vitals, ammo cells, score, time, accuracy, tier, streak, elite warning, and persistent high score.
7. Responsive/performance pass — touchpad calibration, mobile controls, portrait gate, landscape request, safe areas, mobile enemy cap, and lean Web export.
8. QA — script parse, runtime boot, deterministic combat smoke test, desktop browser screenshots, mobile landscape/portrait screenshots, and console-error check.
