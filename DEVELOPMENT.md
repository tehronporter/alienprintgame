# Development workflow

## Local run

```sh
godot --editor project.godot
```

## Rebuild the Web export

```sh
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
```

## Regenerate Blender source assets

```sh
blender --background --python tools/generate_neon_mall.py
```

## Commit rhythm

- Keep commits focused on one gameplay, art, or deployment change.
- Run the Godot parser check before committing.
- Re-export `build/web` whenever runtime code changes.
- Use the browser smoke test before pushing a public Web build.

The first post-launch polish pass tracks live shooting accuracy and displays the actual reserve ammunition count in the HUD.

## GitHub Pages

The `main` branch deploys the checked-in `build/web` directory through `.github/workflows/deploy-pages.yml`.
