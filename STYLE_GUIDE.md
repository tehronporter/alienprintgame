# Neon Mall Style Guide

## Visual rules

- Background, voids, and unlit surfaces are near-black.
- Linework is neon green with occasional dim green construction marks.
- Shapes should feel drawn by hand: uneven spacing, chunky proportions, imperfect silhouettes.
- Use landmarks as readable silhouettes, not photorealistic architecture.
- Prefer emission strokes and thin geometry over detailed textures.
- Keep the screen mostly black so the player’s eye is drawn to green threats, the weapon, and the HUD.

## Gameplay read

- Scout: small, fast, bright eye line.
- Standard: medium humanoid with a readable weapon silhouette.
- Bruiser: oversized body and slow approach.
- Elite: oversized, high-contrast threat that announces a survival milestone.

## Performance rules

- Use the Compatibility renderer for Web export.
- Reuse enemy nodes through the pool.
- Avoid dynamic global illumination, high-resolution textures, and particle-heavy effects.
- Keep landmark meshes modular and low-poly.
- Prefer one material per visual role: black fill, dim green structure, bright green ink.
