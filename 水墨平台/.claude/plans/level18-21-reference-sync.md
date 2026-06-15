# Plan: Sync levels 1-20 with GitHub reference and preserve current level 18 as level 21

## Goal

Use `https://github.com/Va11ha1la/test3D.git` → `水墨平台` as the reference for the first 20 levels. The local current level 18 (`墨竹行`, implemented by `traceKey = "bamboo"` plus the local bamboo-scroll runtime) should be appended as level 21.

## Findings

- Local level order is defined in `scripts/src/00_state_levels_keys.lua` inside `LEVELS`.
- Local levels 1-17 already match the reference project.
- The reference `水墨平台` has levels 18-20:
  - 18: `trace_zhumei`, `traceKey = "zhumei"`, name `水墨竹梅`
  - 19: `trace_forest`
  - 20: `trace_water`
- Local currently has level 18 changed to `traceKey = "bamboo"`, name `墨竹行`, plus extra files:
  - `scripts/src/87_trace_ipoints.lua`
  - `scripts/src/88_bamboo_scroll.lua`
  - enhanced `scripts/src/85_trace_levels.lua`
  - enhanced trace HUD in `scripts/src/90_world_seal_runtime.lua`
- Reference project has no `87_trace_ipoints.lua` or `88_bamboo_scroll.lua`. Keeping these is necessary for local level 21.
- `tools/build_main.ps1` bundles all `scripts/src/*.lua` by filename into `scripts/main.generated.lua`.

## Implementation steps

1. Edit `scripts/src/00_state_levels_keys.lua`:
   - Change the existing level 18 entry back to the GitHub reference values:
     - `traceKey = "zhumei"`
     - `name = "水墨竹梅"`
     - `title = "水墨平台跳跃 - 竹梅画卷"`
     - `seal = "梅"`
     - reference note text.
   - Add a new final level entry after current level 20:
     - `id = "trace_bamboo_scroll"`
     - `trace = true`
     - `traceKey = "bamboo"`
     - `name = "墨竹行"`
     - `title = "水墨平台跳跃 - 墨竹长卷"`
     - `seal = "竹"`
     - reuse the current local level 18 physics/colors/size values.
   - This makes indices 1-20 match the reference while preserving local bamboo-scroll as index 21.

2. Keep local trace runtime support:
   - Keep `scripts/src/87_trace_ipoints.lua` and `scripts/src/88_bamboo_scroll.lua`.
   - Keep the local enhanced `scripts/src/85_trace_levels.lua`, because it supports both reference `zhumei` and local `bamboo` via `generateBambooScroll()`.
   - Keep local trace HUD in `scripts/src/90_world_seal_runtime.lua`, so level 21 can show `补笔 x/y`; optionally set `loadLevel(1)` to match reference startup if desired. I will keep current startup unless user explicitly wants level 1 on launch.

3. Rebuild generated Lua:
   - Run `powershell.exe -ExecutionPolicy Bypass -File tools/build_main.ps1` from project root.
   - This updates `scripts/main.generated.lua` from source chunks.
   - Also copy/regenerate `scripts/main.lua` if project convention expects both `main.lua` and `main.generated.lua` to stay in sync (currently both are modified and appear to contain the bundled runtime).

4. Validate:
   - Verify level list is 21 entries and indices 18-21 are: `zhumei`, `forest`, `water`, `bamboo`.
   - Search generated output for `trace_bamboo_scroll` and `traceKey = "zhumei"`.
   - Optionally launch local UrhoX runtime with `scripts/main.generated.lua` for smoke testing.

## Files expected to change

- `scripts/src/00_state_levels_keys.lua`
- `scripts/main.generated.lua`
- Possibly `scripts/main.lua` if kept as the same bundled content.

## Files intentionally not overwritten from GitHub

- `scripts/src/85_trace_levels.lua`
- `scripts/src/87_trace_ipoints.lua`
- `scripts/src/88_bamboo_scroll.lua`
- `scripts/src/90_world_seal_runtime.lua`

Reason: blindly replacing these with the GitHub versions would remove the local bamboo-scroll level that must become level 21.
