# Progress

## 2026-09-20

- Cleaned up the repo: removed stray Godot autosave `.tmp` files, gitignored
  local AI-assistant tooling (`.codex/`, `addons/godot_ai/`,
  `addons/godot_mcp_toolkit/`), and committed the placement-foundation work
  from the previous session along with `.mcp.json`.
- Implemented the first bandwidth-capacity mechanic: each `CellTower` now has
  a `capacity` (5G: 150, Ethernet: 120) and tracks `current_load` from the
  buildings it serves. This is the first real move from "in range = done"
  toward the TelCom concepts in AGENTS.md — bandwidth allocation and
  congestion control.
- `refresh_network()` in `ui/relayed.gd` now assigns each building to its
  *nearest* matching-network tower (not just "any tower in range"), sums
  bandwidth demand per tower, and flags a tower `is_congested` once its load
  exceeds capacity.
- Buildings now have three visible states instead of two: white (served,
  under capacity), orange (served, but the assigned tower is congested — a
  stand-in for packet loss until a dedicated visual is built), and red (no
  coverage). `Building.set_connected()` was renamed to `set_network_state()`
  to carry both flags.
- Round completion now requires zero congestion, not just full coverage — a
  building connected to an overloaded tower no longer counts as "online".
  This reuses the existing round-2/round-3 demand growth
  (`apply_round_demands()`) as the congestion trigger: round 1's starting 5G
  load (150) exactly matches one tower's capacity, so it stays solvable with
  a single site; round 2's added demand (+75) and round 3's added Ethernet
  demand (+90) push each network over capacity, forcing the player to place
  a second tower and split the load — not just extend range.
- Added a congestion count to the coverage HUD line and to the building info
  panel's network label ("(congested)" / "(no coverage)").

## Decisions and gotchas (2026-09-20)

- Tower→building assignment is nearest-tower-wins, computed fresh in
  `refresh_network()` on every placement/undo. There is no persistent
  wiring/pathing yet — AGENTS.md's `AStarGrid2D` routing and visible wire
  paths are still not implemented; this session only added the *load*
  dimension (bandwidth/congestion), not the *routing* dimension (paths,
  crossing constraints). That's the next mechanic to add.
- Found and fixed a broken local Godot install: `Downloads\Godot_v4.7.2-
  stable_win64.exe` was actually a folder (missing the real 180MB engine
  binary, only the console launcher + an unrelated installer inside). Headless
  testing for this session used the real executable extracted from
  `Godot_v4.7.2-stable_win64.exe.zip` into a scratch temp folder instead.
  The Downloads folder itself was left untouched — worth fixing so
  `--headless` testing is easy to repeat next session.
- Verified with a headless project import and an 8–10s headless scene run of
  `scenes/relayed.tscn`: no parser/runtime errors. Full interactive
  verification (placing towers, triggering congestion by hand, confirming
  round-2/3 force a second tower) still needs a normal editor run — headless
  mode has no input to drive placement.

## 2026-09-19

- Completed the current goal's player-placement foundation in `ui/relayed.gd`.
  The existing isometric `Ground` TileMapLayer is now the authoritative grid:
  placement converts pointer positions to `Vector2i` cells with
  `local_to_map()`, then returns the item to the cell centre with
  `map_to_local()`.
- Renamed the variable `round` to `current_round` in `ui/relayed.gd` to resolve a naming conflict with the built-in Godot `round()` function.
- Added grid-snapped placement for 5G and Ethernet coverage sites, plus a
  basic player-placeable network-demand building. Empty or occupied cells are
  rejected, including cells already occupied by the map's initial buildings.
- Added Undo (including Ctrl+Z) and Reset controls. They remove only
  player-made placements and refund their credits; authored round demand
  buildings remain intact.
- Kept the initial network puzzle and its three-round progression. Round-added
  demand buildings now also snap to the grid and are tracked separately so a
  player building cannot prevent a later round from spawning its intended
  demand.

## Decisions and gotchas

- Grid coordinates are stored as `Vector2i` dictionary keys. World positions
  are used only for rendering, after conversion back from their grid cell.
- The `Ground` TileMapLayer is the buildable-area authority: a cell without a
  ground tile is not a valid placement target.
- Newly placed buildings use the existing 5G demand model so their relationship
  to the TelCom gameplay is explicit: each represents a bandwidth consumer
  that must receive compatible coverage.
- A headless Godot executable was not available on the system PATH during this
  session, so runtime verification still needs to be run in the Godot editor.
- Fixed scene-load error from the menu: the road atlas in `TileSets/Ground.tres`
  declared four 128x64 isometric tiles while its region size incorrectly covered
  the entire 257x129 source texture. It now uses a 128x64 atlas region, allowing
  all declared tile coordinates to load.
- Changed player building placement to a hold-drag-release flow with a
  grid-snapped preview. The preview shows valid cells in blue and invalid cells
  in red; it remains active after an invalid release so placement can be retried.
  Mouse and touch drag input are both supported.
- Dynamically placed building sprites are now bottom-anchored and assigned above
  the ground layer, preventing their artwork from rendering beneath map tiles.
- Extended the same hold-drag-release interaction to 5G and Fiber sites. Their
  tower preview uses the same valid/invalid grid feedback, and placed tower
  sprites are bottom-anchored above the ground layer.
- Fixed the persistent building-info side panel: because it is an autoload, it
  now explicitly hides before returning to the main menu and again when that
  menu becomes ready.
