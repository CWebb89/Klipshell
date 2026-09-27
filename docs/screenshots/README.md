# Screenshots

Nine captures live in `~/Pictures/screenshots/`. Eight are installed here, one
per view, at 1911×1071 (the window, cropped off the 1920×1080 monitor). The
README's Screenshots section uses all eight.

| File | View |
|---|---|
| `dashboard.png` | Dashboard, mid-print |
| `console.png` | GCode console |
| `gcode-files.png` | G-CODE FILES |
| `history.png` | History |
| `heightmap.png` | Heightmap |
| `gcode-viewer.png` | GCODE VIEWER |
| `machine.png` | MACHINE |
| `layermind.png` | LAYERMIND |

Still wanted: `settings.png` (the six-tab popup) and a short `demo.mp4`. The
popup is an in-window scrim overlay, not a layer surface, so `shot window` is its
capture tool — `shot popup` is for real layer-shell surfaces, which klipshell
doesn't open.

## Capturing

One instance at a time, so check first:

```fish
quickshell list -p $PWD
quickshell kill -p $PWD   # only if one is already running
```

Then launch-and-capture on a fresh empty workspace, which waits for the window to
map and settle before shooting:

```fish
shot app /tmp/view.png -- quickshell -n -p $PWD
shot app docs/screenshots/demo.mp4 --video --dur 30 -- quickshell -n -p $PWD
```

`shot app` grabs the whole focused monitor, so the wallpaper and the compositor's
window border end up in the frame. The eight installed here were cropped back to
the window:

```fish
magick /tmp/view.png -crop 1911x1071+0+0 +repage docs/screenshots/machine.png
```

## Which capture is which view

Every view shares the same sidebar, so the active view is identified by the
highlighted nav row, not by the text in frame: rows start at y=35, are 38px tall
on a 42px pitch, and the selected row's fill is `0.08 × surfaceText` over
`surfaceContainerLowest`. That band is unique per capture, which is how the table
above was filled in.
