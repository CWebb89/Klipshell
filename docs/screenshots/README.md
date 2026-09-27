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

Still wanted: `settings.png`, the six-tab popup. It is an in-window scrim
overlay, not a layer surface, so `shot window` is its capture tool. `shot popup`
is for real layer-shell surfaces, which klipshell doesn't open.

The demo video lives in `../video/`.

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
shot app /tmp/demo.mkv --video --dur 120 -- quickshell -n -p $PWD
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
above was filled in. The same detector reads a recording frame by frame, which is
how the demo video's tour was mapped.

## Demo video

`../video/klipshell-demo.mp4` came from a 1920×1080 60fps H.264 MKV recorded at
07:23 on 2026-09-27 (13 MB). It carried a digitally silent Opus track, so the
audio was dropped rather than transcoded. Re-encoded to CRF 23, `-preset slow`,
with `+faststart` for progressive playback: 8.1 MB, same 1080p60.

```fish
magick frame.png -crop 1911x1071+0+0 +repage -resize 1400x -strip \
  -fill 'rgba(20,19,24,0.72)' -stroke '#c8bfff' -strokewidth 3 \
  -draw 'circle 700,392 700,326' -stroke none -fill '#c8bfff' \
  -draw 'polygon 686,366 732,392 686,418' -quality 90 \
  docs/video/klipshell-demo-poster.jpg

ffmpeg -i source.mkv -c:v libx264 -crf 23 -preset slow -pix_fmt yuv420p -an \
  -movflags +faststart docs/video/klipshell-demo.mp4
```

The poster is a real frame from 18s (the bed mesh), with the play badge drawn on.

## Serving the video

GitHub will not play this MP4, and neither will the two obvious links, both of
which were checked against the live repo:

| URL | What happens |
|---|---|
| `/blob/main/docs/video/klipshell-demo.mp4` | refuses to play it |
| `raw.githubusercontent.com/...` | `content-type: application/octet-stream` + `nosniff`, so it downloads |
| `cdn.jsdelivr.net/gh/CWebb89/Klipshell@main/...` | `content-type: video/mp4`, `accept-ranges: bytes`, plays with seeking |

The blob page's own payload says why. At 8.07 MB the file is over GitHub's
threshold, so it is marked unrenderable and the page offers raw instead:

```
blob.blobSize         = 7.69 MB
blob.large            = True
blob.renderImageOrRaw = True
```

Checking that flag is how the size threshold was pinned down, since it is in the
server-rendered payload rather than the visible page:

```fish
curl -s https://github.com/CWebb89/Klipshell/blob/main/docs/video/klipshell-demo.mp4 \
  | python3 -c "import json,re,sys; html=sys.stdin.read(); \
      d=json.loads(re.search(r'react-app.embeddedData\">(.*?)</script>', html, re.S).group(1)); \
      print(d['payload']['codeViewBlobLayoutRoute']['blob'])"
```

So the README's poster links the jsDelivr URL. The file still lives in the repo
as the source that URL serves. jsDelivr caches `@main`, so after re-encoding the
video give it a few minutes before the new bytes are served.

For a player embedded **inside** the README instead, drag the MP4 into the README
editor on github.com. That uploads it to `user-attachments` and returns a URL the
markdown renderer does turn into a player, which also takes the 8 MB back out of
git history. A `<video>` tag in the README is stripped, so that upload is the only
way to get one inline.
