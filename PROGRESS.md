# Progress

## 2026-09-20 (playtest round 2: found the real source of "still a mess")

User reported the map was "still a mess" after the previous density fix,
plus two new specifics: buildings should render above the tile map, the
map should always be plain green land, and towers should always draw in
front of buildings.

- **Root cause was not my downtown paint.** After reverting this session's
  downtown tiles entirely back to grass (confirmed via a full cell scan:
  zero non-grass/concrete/puddle cells left on `Ground`), a screenshot at
  the default camera position *still* showed a fire station and other
  scattered buildings. Dug further and found 13 building tiles painted
  directly onto the **`Buildings` node** — a *separate* `TileMapLayer`
  from `Ground` that otherwise just holds the `Building`/`Building2`
  scene-instance children — scattered around cells (0,-5) through (14,12)
  with no coherent layout (one of each building type 45-55, essentially a
  leftover test placement). Confirmed via `git show 9a57741:scenes/
  relayed.tscn` that this tile data has been there since the **very first
  commit**, predating this session entirely. I'd only ever inspected
  `Ground`'s tile data, never `Buildings`'s, so I never noticed it, and
  every "downtown" screenshot this session actually had this pre-existing
  clutter mixed in with what I assumed was purely my own paint.
- Cleared those 13 leftover cells (`TileMapLayer.erase_cell`, not
  `set_cell` — nothing to paint over them with, they should just be gone).
  The `Building`/`Building2` scene-instance children of that same node are
  untouched. Re-verified with a screenshot: map is now plain grass (green)
  plus the original pre-existing concrete/puddle patch (left alone — it
  also predates this session and wasn't part of the complaint, though it's
  arguably in tension with "map should always be land green"; flagged for
  the user to decide rather than removed unasked).
- This session's own downtown experiment (roads + 12 building types,
  painted then reverted across two rounds today) is fully gone from
  `Ground` — confirmed via a complete `get_used_cells()` scan, not just a
  source-id count.
- **Tower-above-buildings z-order**: real, separate bug. `prepare_placed_
  tower()` and `prepare_placed_building()` both set `z_index = 1`, so
  their relative draw order fell back to Y-sort, which could put a tower
  visually behind/clipped-into a nearby building depending on exact
  positions — this is what the user saw as "glitched/misput." Fixed by
  giving towers `z_index = 2`, strictly above buildings, independent of
  Y-sort. Verified with a screenshot placing a tower next to a building.
- Take-away for any future tile-based city decoration: check **every**
  `TileMapLayer` node in the scene for existing tile data before assuming
  a "clean" baseline, not just the one you intend to paint on.

## 2026-09-20 (playtest fixes: coverage mismatch + cluttered downtown)

Two more issues from the same playtest pass, both traced back to
yesterday's downtown-painting work:

- **"Tower circle range has less radius than its range indicator."** Real
  bug: `_is_routable_cell()` treated decorative downtown buildings as
  routing obstacles, so a gameplay building sitting well inside a tower's
  drawn coverage circle could still fail to connect if the only path there
  happened to run through a downtown block. Confirmed with a scripted
  repro (place a 5G + an Ethernet tower near the starting buildings):
  coverage was 2/3 before the fix, 3/3 after. Fix: decorative tiles (roads
  *and* buildings) no longer block routing at all — they're backdrop only.
  Only real occupied cells (towers, player/demand buildings) block a wire
  path now, so coverage always matches the drawn circle again.
- **"Buildings are a mess."** The downtown block was painted in a
  checkerboard (a building on every other cell), which is far too dense for
  sprites that are 2-3x taller than their single 64px-tall cell footprint —
  looked fine pulled back in my verification screenshots, but crowded and
  overlapping at actual gameplay zoom (confirmed by the user's screenshot).
  Fix: cleared the old block back to grass and repainted with real spacing
  (a building every 3rd cell on each axis instead of every other), moved
  slightly further from the starting buildings, using the same
  GEN_EDIT_STATE_INSTANCE + uid-restoration technique as before. Re-verified
  with a screenshot at the actual default camera position or the previous
  crowding is gone.

## 2026-09-20 (playtest fix: phantom click on scene change)

User playtest report: pressing "New Game" on the Choose Game screen
immediately showed the Chapter Select screen's "LOCKED DISTRICT!" popup —
before clicking anything on that screen.

- Root cause: every screen this session navigates with
  `get_tree().change_scene_to_file(...)` called synchronously from inside a
  Button's `pressed` handler. Godot frees the old scene and instances the
  new one mid-input-dispatch, so the same click event that triggered
  navigation can bleed into whatever control ends up at the same screen
  position in the brand new scene — here, "NEW GAME" and a locked district
  tile happened to land close enough together for the same click to
  register on both.
- Fix: added `UIKit.go_to_scene(path)` (`ui/ui_kit.gd`), which defers the
  scene change via `change_scene_to_file.call_deferred(path)` so it runs
  after the current input event has fully finished dispatching to the old
  scene. Replaced all 18 call sites across every screen script with it (not
  just the one that was reported — the bug applied equally to all of them).
- Not yet re-verified interactively (this fix was made from the bug report
  alone) — worth confirming in the next playtest pass that Choose Game →
  New Game now lands cleanly on Chapter Select with no popup.

## 2026-09-20 (wire routing + downtown)

Implemented the network-routing/wiring mechanic from AGENTS.md (AStarGrid2D
pathfinding, "wires light up on valid connection", "route signals... without
crossing... paths") and painted a decorative downtown into the map.

- **Routing**: `ui/relayed.gd` now builds an `AStarGrid2D` (region = a small
  margin around all occupied cells, rebuilt every `refresh_network()` call)
  and pathfinds an actual grid route from each tower to each building it
  serves, instead of a straight-line/Euclidean-only check. The existing
  Euclidean-range eligibility rule is unchanged (so round balance from last
  session's congestion mechanic isn't disturbed) — among towers already in
  range, the building now picks whichever has the *shortest routed path*,
  not just the closest in a straight line.
- **Wires**: new `ui/wire_layer.gd` (`class_name WireLayer`, immediate-mode
  `_draw()`, same pattern as `CellTower`'s coverage circle) renders each
  computed path as a glowing polyline in the tower's network color, orange
  if the tower is congested. Verified with real rendered screenshots (not
  just headless — headless mode doesn't rasterize) that paths bend around
  obstacles rather than drawing straight lines.
- **Crossing detection**: wires are grouped by tower; a path is flagged
  `crossing` only if it shares a *non-endpoint* cell with a **different**
  tower's wire (wires converging on the same tower's own hub cell is normal
  trunk cabling, not flagged). Crossing buildings get a third visual state
  (violet tint, `Building.wire_crossing`) alongside the existing
  connected/congested states, and the info panel names it. Deliberately
  **not** a round-completion blocker yet — with no way to interactively
  click through the editor this session, gating completion on it risked
  silently making a round unsolvable without being able to verify. Currently
  informational only (status line + visual).
- `is_buildable_cell()` now excludes road/decorative-building ground
  sources (see below) via `NON_BUILDABLE_GROUND_SOURCES`; a separate
  `_is_routable_cell()` excludes only decorative buildings, since wires can
  reasonably run alongside roads.

## 2026-09-20 (downtown)

- Painted a small decorative "downtown" block directly into
  `scenes/relayed.tscn`'s `Ground` TileMapLayer (cells x:13-21, y:-15..-6 —
  east of the three starting gameplay buildings, confirmed via a coordinate
  dump not to overlap them or the round-2/3 spawn points at cells (9,2) and
  (4,-5)). Uses tile sources already registered in `TileSets/Ground.tres`
  but previously unused on the Ground layer: road source 44
  (`RelayedTileSheets/Roads.png`, plain-surface variants — not a directional
  piece set, just texture variety) and 12 building sources (45-59: autoshop,
  barbershop, barn, church, firestation, gasstation, gunshop, hospital,
  house2/house3 variants).
- The whole existing grass field is ~55x93 cells — far larger than the
  actual play area — so downtown occupies one corner as a backdrop; the
  rest stays open grass for player placement, unchanged.
- **How this was done**: a throwaway `SceneTree` script loaded
  `relayed.tscn` with `PackedScene.instantiate(PackedScene
  .GEN_EDIT_STATE_INSTANCE)` (critical — plain `instantiate()` flattens
  the `Building`/`Building2` instanced children of `building.tscn` into
  inline copies, losing their link to the base scene), painted cells via
  `TileMapLayer.set_cell()`, and resaved with
  `ResourceSaver.save(PackedScene.pack(scene), path)`. Verified via `git
  diff` that only the tile data changed (plus one harmless metadata
  reorder) before keeping the result. The resave still stripped every
  `uid="..."` from the scene's ext_resource lines — these were restored by
  hand afterward; something to double check if this technique is used
  again.
- Not committed: the one-off painting script itself (scratch file, same as
  the screenshot tooling from last session).

## 2026-09-20 (storyboard screens)

Implemented the "doable" screens from a UI/UX storyboard document the user
shared (Login, Register, Forgot Password, Settings extensions, Quit
confirmation, Choose Game, Chapter Selection, Player Profile, Story
Event/Objectives). Screens needing dedicated art we don't have use clearly
labeled placeholders.

- New shared UI helper `ui/ui_kit.gd` (`class_name UIKit`, static factory
  functions) builds all Control styling in code — same pattern as
  `build_hud()` in `ui/relayed.gd` — so each screen script stays focused on
  layout/logic. Buttons, panels, text fields, and a reusable
  `show_confirm_dialog()` all live here.
- 8 placeholder SVG icons added under `ui/icons/` (lock, star, person, phone,
  signal, wrench, gear, clipboard) since neither asset pack has UI icons.
  The Google sign-in button is a neutral placeholder, not Google's actual
  branded logo — real Google Sign-In needs their official branding assets
  before shipping.
- New scenes: `scenes/login.tscn`, `register.tscn`, `choose_game.tscn`,
  `chapter_select.tscn`, `player_profile.tscn`, `story_event.tscn` — each a
  minimal `Control` root whose script builds the UI in `_ready()`.
- New autoloads: `AuthState` (in-memory login/username stub — no Firebase
  yet, matches AGENTS.md's stated but unimplemented Firebase Auth
  architecture) and `GameProgress` (real local save to
  `user://save_data.json` for chapter unlocks + stars, per AGENTS.md's Save
  System section — this is the first actual implementation of that section,
  previously only described).
- Project entry point (`run/main_scene`) changed from `main_menu.tscn` to
  `login.tscn`. Full flow: Login/Register → Choose Game (New/Continue, gated
  on save existence) → Chapter Select (6 chapters, locked/unlocked, stars,
  Play/Replay/locked popups) → Story Event (objectives) → `relayed.tscn`
  gameplay. Finishing all 3 rounds in `relayed.tscn` now calls
  `GameProgress.set_chapter_stars()` (flat 3 stars — no scoring rubric
  exists yet) and `unlock_next_chapter()`, so the chapter-select stars/locks
  are real, not decorative.
- `scenes/main_menu.tscn` is **not deleted** but is no longer the entry
  point — it's orphaned from the new flow. Its Start/Settings/Quit buttons
  still work if opened directly (useful as a dev shortcut into
  `relayed.tscn`), and Quit now goes through the same confirm dialog.
  Worth deciding later whether to repurpose or remove it.
- `ui/back_to_mm.gd` (in-gameplay back button) and `ui/control.gd` (Settings
  back button) now return to `chapter_select.tscn` instead of
  `main_menu.tscn`, matching the new hub screen. Settings' back button
  target is stored in `GameProgress.settings_return_path` so it can still
  return to `main_menu.tscn` when reached from there directly.
- Settings screen (`ui/settings.gd`) extended in place (existing camera
  speed slider untouched): Audio slider is real (wired to
  `AudioServer` master bus volume), Notifications toggle is a stub
  (`GameSettings.notifications_enabled`, no push-notification system
  exists), Sign Out is real (`AuthState.logout()`), Quit Game routes through
  the shared confirm dialog.

## Gotchas found this session

- `TextureRect.expand_mode` defaults matter even when the control has
  `PRESET_FULL_RECT` anchors: `EXPAND_FIT_WIDTH_PROPORTIONAL` (used
  originally in `UIKit.icon()` and the chapter-select district icon) lets
  the texture's native pixel size leak into the *minimum size* calculation,
  which can override `custom_minimum_size` and blow up the control's actual
  rect — this showed up as the chapter-select ground tiles and district icon
  overflowing their 100×100 button at 390px width. Fixed by setting
  `expand_mode = EXPAND_IGNORE_SIZE` wherever a fixed display size is
  wanted regardless of the source texture's resolution. `UIKit.icon()` now
  defaults to this; watch for the same issue in any future TextureRect use
  with a non-icon-sized source texture.
- No GUI automation is available in this environment to click through the
  editor by hand. Verification instead used: (1) a headless project
  import + a short headless run of every scene to catch parser/runtime
  errors, and (2) a throwaway `SceneTree` script
  (`await process_frame` × a few, then `get_viewport().get_texture()
  .get_image().save_png()`) launched non-headless at `--resolution 390x844`
  to get real rendered screenshots for visual review — this is how the
  `expand_mode` bug above was actually caught. That script and a temporary
  `_icon_test.tscn`/`.gd` scene were scratch files, not committed.
- Local Godot install problem (not fixed, just worked around): `Downloads\
  Godot_v4.7.2-stable_win64.exe` is a folder, not an executable — it's
  missing the real ~180MB engine binary and only contains the console
  launcher plus an unrelated installer. Testing this session extracted the
  real executable from `Godot_v4.7.2-stable_win64.exe.zip` into a scratch
  temp folder instead. Fixing the Downloads folder would make headless
  testing easier to set up next session.

## Not yet implemented (explicitly out of scope this session)

- Story Event's character portrait — needs real 2D character-portrait art;
  current placeholder is a generic silhouette icon. The project's only
  character sprites (`Isometric Suburban Pack/Characters/`) are isometric
  walk-cycles, a different style entirely.
- Chapter Selection's diamond/isometric map arrangement — simplified to a
  plain grid of ground-tile buttons. Same locked/star/popup interaction,
  different (simpler) visual arrangement than the storyboard mockup.
- Per-chapter level content — all "chapters" currently load the same single
  `relayed.tscn` puzzle map (3 rounds). Chapter → level-design mapping is
  future work.
- Objectives progress bar in Story Event is inert (always 0%) — no
  per-objective progress tracking exists yet to drive it.
- Real Firebase Authentication / Firestore — `AuthState` is a pure
  in-memory session stub.

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
