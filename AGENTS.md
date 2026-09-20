# Relayed — Project Instructions

This project is a prototype of the team's capstone manuscript, "RELAYED:
A Telecommunication-Inspired Mobile Game" (BS Information Technology
proposal, University of Cebu Lapu-Lapu and Mandaue). The manuscript is
the authoritative source for scope, terminology, database schema, and
game design — this file summarizes it for day-to-day coding, but defer to
the manuscript itself when the two disagree. Per the manuscript's List of
Modules, the user (Estrada, Sebastian Clark) personally owns the
**Gameplay Module** (Puzzle/Drag-and-Drop/Matching/Tower Placement/City
Management/Mission Completion) and the **Assessment Module** (Chapter
Quiz/Completion Score/Rewards/Star Rating) — everything else (accounts,
story, settings, progress tracking) is a teammate's module, built here as
needed to keep the prototype runnable end-to-end.

## Game
Isometric city-building puzzle game made in Godot 4.7, mobile (Android)
target. 80% puzzle, 20% city-building visual context. Use GDScript.

Single-player, story-driven. The player is a **Telecommunications
Administrator** restoring communication across **Relay City**, told across
**10 chapters** grouped into **Districts** (a District spans a
`chapter_range` of chapters — District ≠ Chapter, don't conflate them).
Each chapter teaches one telecom concept and can use a different gameplay
type (tower-placement puzzle, quiz, drag-and-drop, matching, ...) — not
every chapter has to be the same mechanic.

## Game Concept
The core gameplay is a network routing puzzle where players:
- Allocate bandwidth to city buildings/zones
- Manage QoS (Quality of Service) priority across network paths
- Route signals between nodes without crossing or congesting paths
- Fix network congestion during peak city demand scenarios

Think Mini Metro meets city builder — not the other way around.

## Progression terminology (manuscript's Player Profile schema — use these exact terms, not ad hoc ones)
- **Infrastructure Fund** — in-game currency, earned on chapter completion, spent on placements. Not "credits."
- **XP** — experience points, accumulated across chapters, drives Administration Rank.
- **City Reputation** — overall telecom-satisfaction metric, star-rating based.
- **Administration Rank** — a title derived from XP (starts at "Trainee").
- **Badges** — milestone-based achievement rewards.
- **Stars** (0–3 per chapter) — per-chapter performance rating.

## Architecture
- Backend: Firebase (Authentication + Cloud Firestore) — **not yet implemented**; everything is local-only stubs (`AuthState`, `GameProgress`) for now.
- Frontend: Godot 4.7 + GDScript (mobile-first, Android export)
- Local save: Godot built-in `user://` save files (`GameProgress` autoload)
- Cloud sync: Firebase Firestore, real-time — only needed for auth/sync; core gameplay must work fully offline after login
- Platform tooling: Android Studio / Kotlin / Java for the export pipeline (not game logic)

## AI Systems
- **ALP (Adjustable Learning Program)** — the manuscript's name for this project's AI system. Rule-based, no external API (not an LLM call). Two jobs:
  - Adaptive hint delivery: tracks wrong attempts and time-on-task per chapter; surfaces a contextual hint (progressively more specific) when a player is struggling, without revealing the answer outright.
  - Performance tracking: records accuracy, attempt count, and completion time per chapter (manuscript: `ALP_SESSION`, `CHAPTER_PROGRESS` collections).
  - Non-punitive and self-paced by design — this is the same spirit as the existing "never punish exploration" rule below, just formalized with a name and a data model.
  - **Not yet implemented** in this prototype.

## Core TelCom Concepts the Game Teaches
These must be reflected in puzzle mechanics, not just flavor text:
- Bandwidth allocation (routing capacity between nodes)
- Quality of Service / QoS (priority lanes for different traffic types)
- Network routing (finding paths between source and destination nodes)
- Congestion control (managing traffic under peak load)
- Latency (delay penalty when paths are overloaded)
- Packet loss (visual failure state when congestion is unresolved)
- Node connection (linking towers, buildings, and infrastructure)

## Level Structure
- Early levels: basic node connection, simple bandwidth allocation
- Mid levels: QoS priority management, multi-service balancing
- Advanced levels: resource optimization, failure recovery, efficiency scoring
- Each level introduces exactly ONE new mechanic before combining

## Puzzle Design Rules (important)
- Use `Vector2i` not `Vector2` for all grid coordinates
- Always provide undo (Ctrl+Z) and reset button — never punish exploration
- Visual feedback must be instant — wires light up on valid connection
- Introduce each mechanic in isolation before combining with others
- Detect and prevent softlocks before the player triggers them
- No punishment for experimenting — wrong connections should be undoable

## Grid & Isometric Setup
- TileMap node for the isometric grid
- Y-sorting enabled — buildings must render in correct depth order
- AStarGrid2D for routing puzzle pathfinding between nodes
- Buildings snap to grid (no free placement)
- Grid coordinates: always `Vector2i`, never `Vector2`

## Adaptive Difficulty (GDScript reference)
```gdscript
func adjust_difficulty(player_score: int, current_level: int) -> void:
    if player_score < 40:
        difficulty = "easy"    # reduce bandwidth demand, fewer nodes
    elif player_score < 70:
        difficulty = "medium"  # standard scenario
    else:
        difficulty = "hard"    # increase QoS complexity, more zones
```

## Save System
- Local save: `user://save_data.json` via Godot's FileAccess (`GameProgress` autoload — implemented)
- Cloud save: Firebase Firestore (`SAVE_DATA` collection: current chapter + serialized city state) — **not yet implemented**
- On launch: load local first, then sync from cloud if online
- Never block gameplay waiting for cloud sync

## Coding
- Prefer small, reusable scripts
- Don't rewrite existing systems unless necessary
- Explain major changes before making them
- Keep scene organization clean
- One responsibility per script — routing logic ≠ UI logic ≠ save logic

## Autoloads (actual, as implemented)
- `GameSettings` — camera speed, audio volume, notifications (session/local settings, not player progress)
- `AuthState` — in-memory login/username stub, standing in for Firebase Authentication
- `GameProgress` — the Player Profile stack (Infrastructure Fund, XP, City Reputation, Badges, Rank, chapter unlocks/stars, Districts), persisted to `user://save_data.json`
- `BuildingInfoPanel` — the building detail overlay

## Current Goal
Terminology and progression stack now align with the manuscript (this
session). Next candidates, not yet decided: more chapters with distinct
gameplay types, the ALP adaptive-hint system, or starting the Firebase
backend — ask before assuming which.

## Important
- The project uses Godot 4.7
- Use the existing project structure
- Test changes in Godot when possible
- Don't delete assets or scenes without asking
- The game is single-player only — no multiplayer infrastructure
- Mobile-first — test UI at 390×844 (iPhone 14 portrait) resolution
- Networking and telecommunications are siblings — mechanics should
  feel like real network decisions, not arbitrary puzzle rules

## Update PROGRESS.md with
- What was completed this session
- Key decisions made and why
- Any gotchas or dead ends to avoid
- Current adaptive difficulty state and tuning notes
- Any TelCom concept newly implemented and how it maps to gameplay