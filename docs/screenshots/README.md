# Screenshots

Drop captures here using the filenames below and the README's screenshot grid
picks them up (the `<img>` block is in `README.md` under **Screenshots** —
uncomment it once the files exist).

| Filename | View | Notes |
|---|---|---|
| `dashboard.png` | Dashboard | The full window at 1900×1060 |
| `console.png` | Console | With a few commands sent |
| `gcode-files.png` | G-CODE FILES | |
| `history.png` | History | |
| `heightmap.png` | Heightmap | A mesh with visible deviation reads best |
| `gcode-viewer.png` | GCODE VIEWER | A real model, mid-scrub |
| `machine.png` | MACHINE | |
| `layermind.png` | LAYERMIND | Needs the LayerMind daemon |
| `settings.png` | Settings popup | |

A short demo video is welcome too — record it as `demo.mp4` and link it from the
README's Screenshots section.

## Capturing

The machine-wide `shot` tool handles the workspace juggling so the agent terminal
is never in frame. **One instance at a time**, so check first:

```fish
quickshell list -p $PWD
quickshell kill -p $PWD   # only if one is already running
```

Launch-and-capture on a fresh empty workspace — it waits for the window to map,
settles, then shoots:

```fish
shot app docs/screenshots/dashboard.png -- quickshell -n -p $PWD
shot app docs/screenshots/demo.mp4 --video --dur 30 -- quickshell -n -p $PWD
```

`shot app` grabs the whole focused monitor, so the wallpaper appears around the
window — that's the honest look of the shell in place. For a window-only crop of
an instance that's already running and focused, use `shot window`:

```fish
shot window docs/screenshots/settings.png
```

The settings popup is an in-window scrim overlay, not a separate layer surface,
so `shot window` is the right tool for it too (`shot popup` is for real
layer-shell surfaces, which klipshell doesn't open).

Keep the window at its native 1900×1060 — the README lays images out two per row,
so matching aspect ratios look best. Lossless PNG for the UI; trim the video to
under a minute and keep anything longer out of the tree.
