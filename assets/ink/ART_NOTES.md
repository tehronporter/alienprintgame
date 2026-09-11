# Illustrated National Mall assets

Generated with the built-in imagegen tool for this project, September 11, 2026. Original PNGs are preserved unchanged, including alpha. Godot AtlasTexture regions select the individual assets at runtime. There is no baked reference screenshot behind gameplay.

- `defense-atlas.png`: Capitol, tree, trooper. Its original rifle quadrant is superseded.
- `reinforcements-atlas.png`: bruiser and overlord. Its weapon quadrants are superseded.
- `first-person-weapons.png`: final rifle, scattergun, and pistol viewed from behind, with barrels pointing away from the player.
- `../fonts/Kalam-Regular.ttf`: Google Fonts Kalam, distributed with `../fonts/OFL.txt`.

The supplied National Mall and Washington DC illustrations were visually inspected as the art-direction references. The generated assets use luminous green contours, black interior silhouettes, hatching and handmade details. Generated dimensions were 1254 × 1254; all atlas regions use actual output dimensions.

## Prompt set

Initial atlas: A four-quadrant production sprite atlas on transparent background. Highly detailed hand-drawn fluorescent lime felt-tip outlines, opaque black object interiors, irregular contours, double lines and crosshatching. Separate complete front elevation of the US Capitol with ribbed dome, windows, portico and staircase; lush park tree with scalloped leafy crown, branch forks and hatching; full-body humanoid alien trooper facing viewer with teardrop head, almond eyes, armor and rifle; first-person rifle with gloved arms. No labels, grid, scene or UI.

Reinforcements: Four equal cells, transparent outside silhouettes, black interiors, bold mint-lime handmade outlines and sparse crosshatching. First-person scattergun, first-person pistol, full-body stocky giant alien bruiser with big shoulder pads and gauntlets, and tall crowned alien overlord with pointed shoulder armor and chest diamond. No labels or background. The first weapon results showed too much of the forward-facing muzzle and were replaced.

Final weapon prompt:

Production sprite atlas for a FIRST PERSON SHOOTER. Square canvas with exactly FOUR EQUAL QUADRANTS. Three weapon viewmodels, fourth quadrant blank transparent. TOP LEFT: sci-fi assault rifle and two gloved hands. TOP RIGHT: double barrel sci-fi shotgun and two gloved hands. BOTTOM LEFT: compact sci-fi pistol in two gloved hands. BOTTOM RIGHT: completely empty transparent. Each weapon rendered from the PLAYER'S EYE behind the gun, a true REAR three-quarter first-person aiming perspective, strongly foreshortened. The closest parts are the rear receiver and right hand at LOWER RIGHT of each quadrant. The top of the gun and rear sights visible. Barrel extends AWAY FROM THE VIEWER toward the UPPER LEFT of each quadrant, narrowing with distance, towards a distant target. Muzzle is the FAR END, pointed AWAY from viewer: absolutely NO visible front muzzle holes or forward-facing barrel circles. See back of weapon and sights, not a side-profile gun. Rifle has a rectangular rear holographic sight window through which player looks FORWARD, no large sideways telescopic scope. Weapons should read like real first-person game viewmodels viewed from BEHIND, not someone pointing a gun back at the camera. Entire hands plus long forearms extend all the way down to each cell's lower edge, cropped by that edge, no floating disconnected arms. Fluorescent light green #99ff60 handmade pen outlines on opaque BLACK interiors. Bold wobbly outlines, detailed doodle hatching and small construction marks, matching charming neon ink alien invasion game. No gray or white, no realistic shaded surfaces, no flat green filled panels. Transparent only OUTSIDE silhouettes. All three weapons isolated from each other, each fills its equal cell with small gutters. No lettering, no UI, no background, no captions.
