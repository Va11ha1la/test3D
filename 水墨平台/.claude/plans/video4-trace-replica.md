# Plan: replicate `参考视频4.mp4` as a trace-based level

## Goal

Use the full 15-second video:

`C:\Users\202102-91\Desktop\项目\横板平台跳跃\参考视频4.mp4`

and reconstruct it as a逐帧描摹/trace level: video frames → color layers → camera stitching → polygon layers → collision polygons → Lua integration.

Video metadata from `ffprobe`:

- Resolution: 992 × 432
- FPS: 24
- Duration: 15.041667s
- Frames: 361

## Reference pipeline learned from `docs/kingsbird_level_skill.md`

Key rules to follow:

1. Frame extraction every ~0.5–0.8s.
2. Per representative frame, run KMeans color clustering, not hand-picked colors.
3. Define layers from bright/far to dark/near; parallax increases as colors get darker.
4. Collision = darkest 1–2 foreground layers.
5. Estimate camera displacement with foreground mask + Canny + template matching.
6. Stitch panorama by adding only previously-uncovered regions per layer.
7. Generate polygons once from the panorama layers.
8. Mark spawn/cp/goal/kill on the panorama and use runtime snap-down safety.
9. Validate by loading locally and checking for obvious holes, false collision, or respawn loops.

## Implementation steps

### 1. Build a new video4 stitch script

Create a dedicated script, e.g. `tmp/stitch_video4.py`, based on `tmp/stitch_kb2.py` but adapted to `参考视频4.mp4`:

- Input video path outside project.
- Output folder: `tmp/video4/`.
- Extract frames at roughly 0.5s intervals across the full 15 seconds, probably 30–31 frames.
- Because source resolution is 992×432, either:
  - use native frame size as `FW=992, FH=432`, or
  - scale to a working size if needed; native is preferred for first pass.
- Do not crop unless preview frames reveal UI bars/watermarks. If UI exists, detect/crop after inspecting sample frames.
- Run KMeans on representative sampled pixels to get ~8 dominant colors.
- Assign each pixel to nearest color cluster.
- Exclude very bright/white UI or player/trail pixels using a brightness threshold if needed.
- Use darkest 1–2 clusters for foreground/collision unless inspection suggests otherwise.

### 2. Stitch panorama

Use the existing `est_shift` approach:

- Build foreground masks from collision candidate clusters.
- Use edge template matching to estimate frame-to-frame camera motion.
- Keep the existing synthetic self-test for displacement sign.
- If confidence is low, use a conservative fixed stride prior based on observed camera movement.
- Stitch per layer with the same “only novel pixels” rule.
- Save:
  - `tmp/video4/video4_trace.json`
  - `tmp/video4/pano_video4.png`
  - sample frames and cluster preview images for debugging.

### 3. Generate Lua data

Create a dedicated emitter, e.g. `tmp/emit_video4_trace.py`, based on `tmp/emit_bundle_trace.py`:

- Add a new `TRACE_DEFS["video4"]` entry into `scripts/src/86_trace_data.lua` or a new source chunk if cleaner.
- Use the panorama-generated layers and polygon coordinates.
- Set approximate level config from the panorama:
  - spawn: near left safe foreground top surface, snapped at runtime.
  - cps: 2–4 rough checkpoints across the panorama width.
  - goal: near the far-right route end.
  - kill: below the lowest intended play space.
- Use the existing trace runtime (`generateTraceLevel`, `drawTraceWorld`, `traceCollision`) rather than the bamboo hand-authored runtime.

### 4. Add a new level entry

Edit `scripts/src/00_state_levels_keys.lua`:

- Add a new trace level, likely level 23, for the video replica:
  - `id = "trace_video4"`
  - `trace = true`
  - `traceKey = "video4"`
  - name/title can be temporary, e.g. `参考视频4复刻`.
- Keep existing levels 1–22 intact.

### 5. Build and run

- Run `tools/build_main.ps1`.
- Sync `scripts/main.lua` from `scripts/main.generated.lua` if needed.
- Temporarily set startup `loadLevel(23)` only if useful for preview.
- Launch local UrhoX runtime and inspect.

### 6. Expected first-pass limitations

This first pass should prioritize correct pipeline and visual/collision extraction over perfect gameplay:

- Player silhouette/trail may need cleanup if it becomes foreground collision.
- If the camera motion is not a simple side-scroll, some parts may warp or overlap.
- Spawn/cp/goal will likely need manual adjustment after seeing `pano_video4.png`.
- Color layer selection may require one iteration after sample-frame preview.

## Files likely to change

- New: `tmp/stitch_video4.py`
- New: `tmp/emit_video4_trace.py`
- New output: `tmp/video4/*`
- Modified: `scripts/src/86_trace_data.lua` or a new trace-data chunk
- Modified: `scripts/src/00_state_levels_keys.lua`
- Modified generated bundles: `scripts/main.generated.lua`, `scripts/main.lua`

## Validation

- Check script self-test passes.
- Check `pano_video4.png` visually exists and shows a coherent panorama.
- Check generated `TRACE_DEFS["video4"]` exists.
- Check level count/order includes the new video4 level.
- Launch local UrhoX runtime for smoke test.
