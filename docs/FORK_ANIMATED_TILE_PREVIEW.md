# Animated tile preview (fork feature)

This fork can animate tiles directly in the LDtk editor while the level containing them is active.

The custom lighting-preview feature that was previously bundled with this fork has been removed; this feature is independent and remains enabled.

The preview is intentionally editor-only:

- only the currently active level is animated;
- World mode and inactive levels remain static;
- hidden layers are not refreshed;
- generated PNG/layer exports render the authored tile ID, not a time-dependent preview frame;
- animation metadata stays in normal LDtk tile `customData`, so Unity/importers receive the same source-of-truth values.

## Preferred metadata

Open **Tilesets → Custom data** for the first tile of an animation and store JSON like:

```json
{
  "animation": {
    "frames": [12, 13, 14, 15],
    "frameDurationMs": 100,
    "loop": true
  }
}
```

Any tile ID listed in `frames` resolves to the same preview animation, so placing frame 12, 13, 14, or 15 in the active level will animate the sequence.

## Supported properties

The parser accepts either a nested `animation` object or the same fields at the root when `animated: true` is present.

- `frames`, `tileIds`, or `animationFrames`: array of tile IDs.
- `frameDurationMs`, `durationMs`, or `frameMs`: fallback duration for every frame.
- `frameDurationsMs` or `durationsMs`: per-frame durations.
- `fps`: alternative to a fixed frame duration.
- `loop`: defaults to `true`.
- `mode: "pingpong"`: plays back through the interior frames in reverse after reaching the end.
- `relativeFrames: true`: treats values in `frames` as offsets relative to the tile containing the custom data.
- `frameCount`: creates a consecutive/strided sequence when an explicit frame array is not supplied.
- `startTileId`: optional first tile when using `frameCount`; defaults to the tile containing the metadata.
- `frameStride` or `stride`: tile-ID step when using `frameCount`; defaults to `1`.

Frames can also be objects when individual frame durations are useful:

```json
{
  "animation": {
    "frames": [
      { "tileId": 20, "durationMs": 80 },
      { "tileId": 21, "durationMs": 120 },
      { "tileId": 22, "durationMs": 80 }
    ]
  }
}
```

## Performance behavior

The editor does not redraw animated tiles at a fixed 60 FPS. It calculates the next animation-frame boundary and invalidates only visible tile/auto layers in the active level when a frame actually needs to change. When no animated tiles are present, the timer falls back to a low-frequency metadata check.
