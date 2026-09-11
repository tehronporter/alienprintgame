# Neon Mall Production Plan

## Fortnite-familiar gameplay rule

Use conventions that millions of desktop and mobile shooter players already understand while keeping Neon Mall's identity, camera, art, enemies, map, names, and interface original.

- Desktop: WASD, hold-to-fire, right-click ADS, Shift sprint, Space jump, C crouch, number-key/mouse-wheel weapon slots, Esc pause, and editable sensitivity.
- Mac touchpad: reduced look multiplier and per-device saved calibration.
- Mobile: left movement stick, right drag-look zone, large dedicated action targets, selectable auto-fire, jump, weapon swap, reload, sprint and aim toggles, landscape layout, and portrait rotation gate.
- Combat readability: visible projectiles, weapon-specific recoil/spread, weak-point confirmation, damage direction pressure, pickups, compact weapon slots, and one-action restart.
- Responsiveness: immediate acceleration on the ground, softer air control, FOV change while sprinting/aiming, contextual HUD state, and interruption-safe pause on lost focus.

This is an interaction benchmark, not a visual or content clone. Do not use Fortnite assets, terminology, interface artwork, map layouts, characters, sounds, or proprietary systems.

## Phase status

1. Gameplay foundation — implemented sprint, jump, crouch, ADS, acceleration, air control, focus pause, touchpad tuning, mobile controls, and reduced-motion mode.
2. Weapon expansion — implemented rifle, scattergun, and pistol with independent ammunition, switching, spread, recoil, reload timing, weak points, and HUD slots.
3. Enemy encounters — implemented melee roles, ranged strafing rifle/elite behavior, pooled visible projectiles, local separation, attack pacing, and off-reticle spawning preference.
4. Map traversal — implemented five named landmark lanes, recovery-space props, readable ground labels, cover loops, and DC landmark anchors.
5. Ink presentation — implemented unshaded neon materials, cached environment materials, hero viewmodel, alien silhouettes, hit/death effects, scan treatment, and landmark detail.
6. Audio atmosphere — implemented procedural Web-safe cues for shots, scattergun, reload, switching, hits, weak points, damage, pickups, death, and elite warnings.
7. Progression — implemented streak scoring, resource drops, rapid-fire pickups, two-minute three-choice field mods, high scores, and best survival persistence.
8. Menus/accessibility — implemented start, pause, death, calibration, auto-fire, reduced motion, mobile orientation, and control help flows.
9. Performance — implemented fixed pools for 48 enemies, 32 projectiles, and 16 pickups; mobile active cap; cached world materials; short-lived effects; and lean exports.
10. Verification/release — automated parse, combat, gameplay-system, endurance, Web export, desktop browser, and mobile viewport checks before deployment.

## Next content milestone after this systems pass

- Replace shared weapon geometry with three fully distinct Blender viewmodels and reload animations.
- Add directional audio and a layered threat-tier music loop using licensed/original recordings.
- Add obstacle-aware navigation meshes once the final cover layout stops changing.
- Conduct real-device iPhone, Android, and Mac touchpad playtests; tune sensitivity and button placement from observed sessions.
- Add optional player-customizable mobile HUD dragging after the default layout has passed usability testing.
