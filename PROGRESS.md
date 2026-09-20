# Progress

## 2026-09-21 (building info panel stuck on screen after district completion)

User report, with a screenshot: the Story Event "Welcome to Chapter 4"
screen still showed the building-info side panel ("Riverside Apartments...
Prefers: Ethernet") from the previous district's gameplay, overlapping the
new screen.

- `BuildingInfoPanel` is an autoloaded `CanvasLayer` (`ui/canvas_layer.gd`,
  via `scenes/BuildingInfoPanel.tscn`) that draws on top of every scene, so
  it stays visible across a scene change unless explicitly hidden. Only two
  call sites did that — `main_menu.gd` and `back_to_mm.gd`'s `_ready()`
  (from an earlier session's fix, see the "phantom click" era entries
  below) — but `advance_round()` in `ui/relayed.gd` navigates straight to
  `story_event.tscn` on completing the final round ("Next District")
  without going through either of those, so a panel left open from clicking
  a building earlier in the district stayed on screen through the
  transition. Also affected the "Play Again" path on the very last chapter
  (`get_tree().reload_current_scene()`), for the same reason.
- Fixed at the single chokepoint every scene transition already goes
  through instead of patching one call site at a time: `UIKit.go_to_scene()`
  now calls `BuildingInfoPanel.hide_panel()` before deferring the scene
  change, so every one of its 18+ existing call sites (login, sign-out,
  chapter navigation, etc.) is covered, present and future. Added the same
  call directly to the one remaining path that doesn't use
  `go_to_scene()` — the last-chapter `reload_current_scene()` branch in
  `advance_round()`.
- Verified with two scripted regressions (not committed): opening the panel
  on a building then completing the final round and pressing "Next
  District" — panel now hidden on arrival at Story Event; and the same but
  ending on the actual last chapter ("Play Again" reload) — panel hidden
  after reload. Also re-ran the full scene-load regression across all 9
  non-gameplay scenes — all clean.

## 2026-09-21 (round-demand buildings cramped/overlapping)

User report, with a screenshot: "all are cramped and overlapping with each
other" — a "Network Complete" screenshot showing Corner House, Riverside
Apartments, the two towers, and the original buildings all visually piled
on top of one another near the north-east corner of the map.

- **Root cause #1 — unscaled sprites.** `spawn_building()`/`place_building()`
  never applied any scale to a building's `Sprite2D`; it rendered at the
  source texture's native pixel size. The building art assets vary hugely in
  native size — a plain house texture is 225×193px, the apartment complex
  texture is 425×345px — while the scene's *original* three starting
  buildings were each hand-scaled in the editor (~0.7-0.75×) to a consistent
  visual footprint. Round-demand buildings (`spawn_building()`) and
  player-placed buildings (`place_building()`) both skipped that scaling
  entirely, so a building using the apartment texture rendered nearly twice
  as wide as the largest hand-scaled original building. Fixed by normalizing
  every building sprite to a fixed rendered width
  (`BUILDING_SPRITE_TARGET_WIDTH = 170`, chosen to match the original
  buildings' existing scale) in `prepare_placed_building()`
  (`ui/relayed.gd`), rather than leaving scale at each texture's native
  size.
- **Root cause #2 — spawn positions never accounted for sprite footprint.**
  Earlier sessions' fixes to Corner House/Riverside Apartments' spawn
  positions (see the puddle-patch and hand-edited-road entries below) only
  ever checked that the spawn *cell* was clear of terrain and other
  buildings' *cells* — never each building's actual rendered pixel
  footprint, which is far larger than one grid cell. In particular,
  `Building2` (an original, hand-placed "Apartment" building using the same
  425×345 apartment-complex texture, scaled *up* to ~1.18× in the editor)
  has an effective on-screen footprint of roughly 500×400px — Corner House
  and Riverside Apartments' previous spawn positions both landed inside that
  box. Moved both to genuinely clear grass well outside every existing
  building's footprint: Corner House to `Vector2(1700, 20)`, Riverside
  Apartments to `Vector2(1900, -115)` — found by scanning ground-tile source
  ids in a grid around the cluster (avoiding the user's hand-added road,
  source 44) and confirmed visually with rendered screenshots, not just
  grid-cell math (a plain grid-cell check is exactly what missed this the
  first two times).
- **Verified no solvability regression**: bandwidth/capacity/network-type
  values were untouched — only position and sprite scale changed — but
  moving buildings further apart could in principle put one out of every
  tower's coverage radius (300). Scripted a full 3-round playthrough
  (`test_full_playthrough.gd`, not committed): places 2×5G + 2×Ethernet
  towers at positions chosen to reach every building, and confirmed
  `round_complete` triggers correctly for all 3 rounds and `Network
  Complete` is reached, with credits tracking correctly through each
  round's completion bonus. Also re-ran the existing round-1-3 congestion
  design's tower-count requirement (2 towers per network, due to capacity,
  not range) and confirmed it's unchanged — my position change means the
  2nd 5G tower now *must* be placed near Corner House specifically (they're
  no longer in range of a single central tower), which is a minor puzzle
  behavior change but not a correctness regression.
- Verified with a headless project import (clean) and rendered screenshots
  at multiple zoom levels, including one with towers placed to match the
  user's reported scenario — all 5 buildings and both towers now render as
  clearly distinct, non-overlapping objects.

## 2026-09-20 (baked runtime-built screens into real editor scene nodes)

User noticed every `.tscn` I'd built this session (login, register,
choose_game, chapter_select, player_profile, story_event, quiz) appeared
**empty** in the Godot editor — no visible/editable child nodes — because
each screen's whole UI was constructed in code inside `_ready()` rather than
authored as real scene nodes, unlike the user's own hand-authored scenes
(`relayed.tscn`, `main_menu.tscn`, `settings.tscn`, `building.tscn`). Asked
to convert all of them to have real child nodes.

- **Technique**: for each screen, (1) added an explicit `.name = "X"` to
  every node the `_ready()` code constructs (Godot auto-names unnamed nodes
  `@ClassName@N`, useless for hand-editing later), (2) ran a one-off
  `SceneTree` script that instantiates the scene with
  `PackedScene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)`, walks the
  tree recursively setting `owner = scene_root` on every descendant (nodes
  `add_child()`ed at runtime never get an owner, and `PackedScene.pack()`
  silently drops any node without one — this was the actual cause of the
  "empty" scenes), then `ResourceSaver.save(PackedScene.pack(root), path)`,
  (3) rewrote the script a second time to reference the now-real nodes via
  `@onready var x = $Path/To/Node` and connect signals in `_ready()`,
  instead of constructing them.
- **Fixed-count-but-dynamic-content pattern**: several screens have UI whose
  element *count* never changes at runtime but whose *text/visibility/tint*
  does — these got baked as always-present nodes with state applied by
  lookup, never conditionally created/destroyed:
  - `choose_game.tscn`: the "No previous session found" label always exists;
    `_ready()` toggles its `.visible` based on `GameProgress.has_save()`.
  - `chapter_select.tscn`: all 10 chapter tiles across 3 district sections,
    and the popup's 3 star icons (`Star0/1/2`), are baked as fixed nodes;
    `_refresh_tiles()` looks them up by name pattern and updates
    modulate/visibility rather than building the grid at runtime.
  - `player_profile.tscn`: `NameLabel`'s text is set from
    `AuthState.username` in `_ready()`, same pattern.
  - `story_event.tscn`: both `ObjectiveLine1` and `ObjectiveLine2` are
    always baked; the quiz chapter (`QUIZ_CHAPTER == 2`) just hides
    `ObjectiveLine2` and sets `ObjectiveLine1`'s text to the quiz's single
    objective, instead of building a variable-length list at runtime.
  - `quiz.tscn`: all 4 `OptionButtonN` nodes are baked; `_show_question()`
    sets each one's `.text` from `QUESTIONS[current_index]["options"]`
    rather than building buttons per-question.
- **Verification per screen** (headless-only testing was not sufficient —
  see "Gotchas" below): (1) headless `--quit --import` for parser errors,
  (2) a real routed-click functional test via `Viewport.push_input()` with
  actual `InputEventMouseButton` press/release pairs (not `emit_signal()`,
  which bypasses hit-testing and would have masked a real click-blocking
  bug the way it did earlier this session — see the "back arrow" entry
  further down), run non-headless at `--resolution 390x844` (headless mode
  silently ignores `--resolution` and defaults to a 64×64 viewport, making
  any position-based click test meaningless), (3) a rendered screenshot
  compared against the pre-conversion layout.
- All 7 screens converted and verified this way: `login`, `register`,
  `choose_game`, `chapter_select`, `player_profile`, `story_event`, `quiz`.
  Final regression: headless project import (whole project, zero errors)
  plus a scripted load-and-instantiate pass over every non-gameplay scene
  (`login`, `register`, `choose_game`, `chapter_select`, `player_profile`,
  `story_event`, `quiz`, `settings`, `main_menu`) — all load clean.
- **Gotchas**:
  - `PackedScene.pack()` needs every node's `.owner` set to the scene root
    or it's silently excluded — the root cause of the original "empty
    scene" complaint.
  - Auto-generated node names (`@Label@5`) survive a naive bake; give every
    constructed node an explicit `.name` *before* baking, not after.
  - A modal/popup's `DismissButton` sitting behind a *centered* panel only
    receives a click if the click lands outside the panel's own bounding
    box (the panel itself defaults to `MOUSE_FILTER_PASS`, letting the
    click fall through to whatever's behind it at that exact point, but a
    click that lands *on* the panel is absorbed by the panel first). This
    is pre-existing behavior in every screen using this Dim+DismissButton+
    CenterContainer modal pattern (chapter_select's district popup,
    player_profile's info/edit panels, quiz's completion overlay) — not
    introduced by this conversion, but worth knowing when writing a click
    test against one: tap a corner, not the button's own computed center.
  - A `SceneTree` test script that manually swaps `current_scene` between
    segments (instead of using `change_scene_to_file`, which frees the old
    scene automatically) must free the previous scene itself — otherwise it
    keeps running (`_process`, input handling) alongside the next segment
    and silently corrupts later click results. Cost real debugging time
    twice in this pass (once for `story_event`'s quiz-chapter segment via a
    leftover `relayed.tscn` instance, once for `quiz`'s completion flow via
    a missing final "Continue" click after the last question — same gap
    noted as a risk earlier this session in `test_quiz_flow.gd`).

## 2026-09-20 (round-demand spawn vs. hand-edited road)

User manually added a road directly to `scenes/relayed.tscn`'s Ground
layer in the Godot editor (a large diamond-shaped street boundary, ~98
cells, source id 44) and asked to fix any building spawn now obstructing
it.

- Checked every round-demand spawn position (`apply_round_demands()` in
  `ui/relayed.gd`) against the new road layout directly, rather than
  guessing from a screenshot: "Riverside Apartments" (round 3, cell
  (5,-12)) now landed squarely on the new road. "Corner House" and the
  three original buildings were unaffected.
- Moved Riverside Apartments to `Vector2(1280, -256)` (cell (9,-9)) —
  clean grass, close to the existing building cluster, not colliding with
  any other occupied cell. Re-verified all 5 buildings' ground source
  after the fix: all on source 1 (grass), none on 44 (road).
- Player-placed towers/buildings were never at risk here — `is_buildable_
  cell()` already excludes road tiles (source 44) from placement, from
  earlier work. This was specifically about the hardcoded round-demand
  spawn positions, which don't go through that check (same class of bug
  as the puddle-patch spawn fix earlier today).
- Confirmed no incidental corruption from the user's manual edit itself
  (checked via headless reimport + full scene regression — all clean).

## 2026-09-20 (quiz district + capstone manuscript alignment)

User shared the team's actual capstone manuscript ("RELAYED: A
Telecommunication-Inspired Mobile Game," BS IT proposal, University of Cebu
Lapu-Lapu and Mandaue). Read it in full — it's a much bigger vision than
what's built (10 chapters, Firebase backend, an adaptive-hint AI system
called the ALP, a full Player Profile progression stack, an admin console)
— and per the List of Modules table, the user (Estrada, Sebastian Clark) is
personally assigned the **Gameplay Module** (Puzzle/Drag-and-Drop/Matching/
Tower Placement/City Management/Mission Completion) and the **Assessment
Module** (Chapter Quiz/Completion Score/Rewards/Star Rating) — confirming
this session's tower-placement puzzle and quiz work were on-target. User
chose to prioritize aligning terminology and the progression stack over
building more chapters or starting the Firebase backend.

- **District 2 is a quiz**, per an earlier request in the same session
  ("the 2nd district would be a quiz type"). New `scenes/quiz.tscn` +
  `ui/quiz.gd`: 6 multiple-choice TelCom questions (QoS, congestion,
  latency, packet loss, bandwidth allocation, routing — the exact concepts
  AGENTS.md lists), wrong answers can retry with no penalty (matches the
  existing "never punish exploration" rule), correct answers show a
  one-line explanation. `story_event.gd` now routes chapter 2's "BEGIN" to
  the quiz instead of `relayed.tscn`, with matching objectives text; this
  is a direct `QUIZ_CHAPTER == 2` special case, not a general "district
  type" system — worth generalizing if more non-puzzle chapters get added.
  Refactored the in-game settings overlay out of `relayed.gd` into
  `UIKit.show_in_game_settings()` so the quiz screen didn't need its own
  copy.
- **GameProgress now carries the manuscript's Player Profile stack**:
  `infrastructure_fund` (renamed from the old ad hoc "credits", and now
  *persistent* across districts rather than resetting to 600 every
  playthrough — spending/earning in one district affects what's available
  in the next, matching "Infrastructure Fund... earned upon chapter
  completion" in the spec), `xp`, `city_reputation`, `badges`,
  `administration_rank()` (an XP-threshold title lookup, starting at
  "Trainee" per the spec's default). `relayed.gd`'s `credits` is now a
  computed property backed by `GameProgress.infrastructure_fund` rather
  than a separate local variable, so every screen sees the same number.
  `TOTAL_CHAPTERS` is 10, not 6. Verified the whole award flow directly:
  first completion of a chapter awards XP/reputation/a badge exactly once,
  replaying the same chapter does not double-award, and spending through
  `relayed.gd`'s `credits` property genuinely mutates
  `GameProgress.infrastructure_fund`.
- **District ≠ Chapter now**, per the manuscript's ERD (a District spans a
  `chapter_range` of Chapters). Added `GameProgress.DISTRICTS` (3 districts
  covering chapters 1-3/4-6/7-10 — names and exact boundaries are
  placeholders pending real content design) and `district_for_chapter()`.
  Chapter Select now groups tiles under a district header with a per-
  district star tally, inside a `ScrollContainer` (10 chapters no longer
  reliably fit one screen the way 6 did) instead of one flat grid.
- **Player Profile's stubs are real now**: View Stats shows rank/XP/
  Infrastructure Fund/chapters/stars; View Achievements lists actually-
  earned badges (two placeholder badges exist — `first_contact`,
  `city_restored` — the manuscript defines the badge *schema*, not
  specific badges); View Reputation shows the real City Reputation number.
- Explicitly **not** done this pass (out of scope for "terms and
  progression," left for later): Firebase Auth/Firestore (still local-only
  stubs), the ALP adaptive-hint AI system, per-chapter distinct gameplay
  types beyond the puzzle/quiz split, building categories/routing/relay
  abilities from the Building Types schema, the admin console, network-
  disruption events (network_attack/infrastructure_failure).

## 2026-09-20 (next district + in-game settings)

Two feature requests from the "Network Complete" screen.

- **Next District after finishing a chapter.** Previously the final
  round's overlay always said "Play Again" and just reloaded the same
  scene (`get_tree().reload_current_scene()`), even though
  `GameProgress.unlock_next_chapter()` was already unlocking the next one
  on completion — there was just no way to actually go play it without
  manually backing out to Chapter Select. Now: if
  `GameProgress.selected_chapter < GameProgress.TOTAL_CHAPTERS`, the
  button reads "Next District" and, on press, increments
  `GameProgress.selected_chapter` and navigates to `story_event.tscn`
  (the same intro/objectives screen every district already starts
  through) instead of reloading. On the actual last chapter it still
  says "Play Again" and replays the same district, since there's nothing
  further to unlock yet (only one puzzle map exists — see "not yet
  implemented" further down). Verified the chapter-increment and
  navigation directly by forcing `current_round` to `MAX_ROUNDS` and
  calling `advance_round()`.
- **In-game settings**, reachable from a new gear icon in the gameplay
  HUD, not just from Chapter Select. This is deliberately an **overlay**,
  not a navigation to `scenes/settings.tscn` — the puzzle's state
  (credits, score, round, placed towers/buildings) lives only in the
  `relayed.gd` instance with no save/resume, so a real scene change to
  reach settings and back would silently discard the whole district in
  progress. `_open_in_game_settings()` in `ui/relayed.gd` builds a small
  panel (camera speed, audio, notifications, Close, Sign Out, Quit Game)
  reusing the same `UIKit` helpers as every other screen, and Close just
  frees the overlay layer. Verified with scripted tests: opening/closing
  it leaves `credits`/`deployed_towers` and `current_scene` completely
  unchanged, and the gear icon itself responds to a real routed click
  (not just a direct function call — see the back-arrow entry below for
  why that distinction matters).
- Caught one real bug while screenshotting the new overlay: the
  "Notifications" label was wrapping one character per line inside its
  horizontal row, because `UIKit.body_label()` always enables word-wrap
  and the label had no guaranteed width in a narrow `HBoxContainer`.
  Fixed by turning off autowrap on that specific label rather than
  changing the shared helper's default (which is reasonable for the
  wider contexts it's normally used in).

## 2026-09-20 (playtest round 5: back arrow genuinely unclickable — real root cause)

User report: "back arrow still unresponsive" on Chapter Select, after the
previous entry's fix (renaming the mislabeled gameplay button). That
previous fix was real but addressed a different button — Chapter Select's
arrow icon had a separate, actual click-through bug the whole time.

- My first diagnosis attempt (emit_signal on the button directly) was
  methodologically wrong for this class of bug: it invokes the connected
  handler directly, bypassing Godot's real hit-testing entirely, so it
  can't detect "button is wired correctly but physically unclickable."
  Re-tested with `Viewport.push_input()` (a real routed click) and
  confirmed: the click did nothing. Root cause: `CenterContainer`s (and
  other layout containers — `VBoxContainer`, `HBoxContainer`,
  `GridContainer`) default to `MOUSE_FILTER_PASS`, not `IGNORE`. A
  full-rect `CenterContainer` added *after* the back button in every one
  of these screens sat on top of it in hit-testing priority — its own
  rect spans the whole screen (regardless of where its centered content
  actually renders), so it claims clicks anywhere on screen, including
  directly over the back button, a separate sibling positioned underneath.
- Fixed at the shared source: `UIKit.centered()`, `UIKit.vbox()`, and
  `UIKit.hbox()` (`ui/ui_kit.gd`) now default to `MOUSE_FILTER_IGNORE` —
  they're pure layout wrappers, and IGNORE lets clicks fall through to
  whatever's actually there while their own button/field children still
  receive clicks normally regardless of the parent's filter. Also fixed
  the handful of `CenterContainer`/`GridContainer`/`HBoxContainer`
  instances constructed directly rather than through those helpers
  (`chapter_select.gd`'s grid, `login.gd`/`register.gd`'s button rows, and
  `relayed.gd`'s HUD containers), plus `story_event.gd`'s `intro_view`/
  `objectives_view` wrapper `Control`s, which had the identical problem
  one level up (full-rect, default filter, added after the back button).
- Modal/popup overlays (login's forgot-password panel, chapter select's
  district popup, player profile's info/edit panels) were **not**
  touched — those correctly rely on their own wrapping `Control`'s default
  `STOP` filter to block background clicks while shown, which is intended,
  not a bug.
- Verification pitfall worth remembering: my first re-test after the fix
  still failed — because it ran via `--headless` without `--resolution`,
  which silently defaults to a tiny **64×64** viewport. At that size, the
  profile/settings buttons (anchored to the right edge with negative
  offsets) land on top of the back button by coincidence, making the test
  meaningless. Real click-routing tests need a non-headless run with
  `--resolution` to get realistic control geometry — headless mode doesn't
  apply `--resolution` at all.
- Re-verified with real routed clicks (not emit_signal) at 390×844 on both
  Chapter Select's and Choose Game's back arrows — both now correctly
  navigate.

## 2026-09-20 (playtest round 4: back button label, building z-order, drag camera)

Three more items from the same playtest pass.

- **"Back arrow doesn't work/redirect to main menu."** Tested the actual
  navigation directly (both Chapter Select's back arrow and gameplay's
  "Back to Main Menu" button) — both genuinely fire and change scenes; this
  wasn't a dead button. The real problem was a label/behavior mismatch:
  the gameplay screen's button is literally labeled "Back to Main Menu"
  but has gone to `chapter_select.tscn` since the navigation flow was
  rebuilt (`main_menu.tscn` is no longer part of the primary flow — kept
  as an orphaned legacy screen per the user's earlier "leave it as-is").
  Renamed the button's text to "Back to Districts" to match what it
  actually does, in `scenes/relayed.tscn` directly (a plain text property,
  not the tile_data — safe to hand-edit, no resave-script needed).
- **"Corner house is in front of apartments."** Real z-order bug: the
  three original scene-authored buildings (`Building`, `Building2`,
  `Building3`) default to `z_index=0` (never set explicitly), while
  round-demand and player-placed buildings get `z_index=1` via
  `prepare_placed_building()` — so a demand building would always draw in
  front of an original building regardless of which one should visually
  occlude the other. Fixed by setting `z_index=1` on `scenes/building.tscn`'s
  root node, so every `Building` instance (scene-authored or runtime)
  inherits the same z-tier by default and Y-sort alone decides draw order
  between them, same fix pattern as the tower-vs-building z-index bug from
  earlier today. Verified both that scene-authored buildings now report
  `z_index=1` and with a screenshot showing correct occlusion.
- **"Want click-and-drag navigation instead of WASD — it's a mobile game."**
  Rewrote `ui/camera_2d.gd`: removed the WASD `_process()` movement
  entirely, replaced with press-drag-release panning (`InputEventMouseButton`
  + `InputEventMouseMotion` for desktop, `InputEventScreenTouch` +
  `InputEventScreenDrag` for touch), 1:1 with the pointer (delta divided by
  current zoom so panning tracks the pointer correctly at any zoom level).
  Explicitly skips panning while `current_scene.is_placing()` is true, so
  dragging to place a tower/building doesn't also drag the camera under it
  — verified with a scripted input test that camera position is completely
  unchanged during a placement drag, and moves correctly (and in the
  correct direction) otherwise. Mouse-wheel zoom (unrelated control)
  untouched. The existing "camera movement speed" setting still applies,
  now as a drag-sensitivity multiplier rather than a WASD velocity.

## 2026-09-20 (playtest round 3: demand buildings spawning on the puddle patch)

User report: "Riverside Apartments" (round 3 demand building) visually
obstructed the pavement.

- Checked its spawn cell directly: `Vector2(620, -120)` maps to cell
  (4,-5), which has ground source 5 — a puddle tile, part of the
  pre-existing concrete/puddle patch flagged (but left alone) in the
  previous entry. The building was spawning *inside* that patch.
- Checked "Corner House" (round 2 demand building) too, since it's spawned
  by the same `spawn_building()` path with no buildability check — same
  problem, also on a puddle tile at its cell (9,2). The user only reported
  Riverside Apartments, but Corner House had the identical bug, so fixed
  both rather than leaving a known twin issue for the next playtest report.
- Moved both spawn positions in `apply_round_demands()`
  (`ui/relayed.gd`) to cells confirmed as plain grass, clear of the patch
  and of each other and the three original buildings: Corner House to
  `Vector2(1450, -280)` (cell (11,-10)), Riverside Apartments to
  `Vector2(700, -380)` (cell (5,-12)). Same district/network/bandwidth/
  round-trigger logic, only the spawn position changed. Verified by
  checking `get_cell_source_id()` at both new cells (source 1, grass) and
  with a screenshot showing both sitting on clean grass.
- `spawn_building()` still doesn't check `is_buildable_cell()` before
  placing (unlike player placement) — worth adding if more demand
  buildings get added later, so a bad spawn position fails loudly instead
  of silently placing on the wrong terrain.

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
