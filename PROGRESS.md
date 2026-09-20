# Progress

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
