# Relayed — Project Instructions

## Game
Isometric city-building puzzle game made in Godot 4.7.
80% puzzle, 20% city-building visual context.
Use GDScript.

## Game Concept
Players act as network administrators managing a growing digital city's
telecommunications infrastructure. The city is the visual skin — the
core gameplay is a network routing puzzle where players:
- Allocate bandwidth to city buildings/zones
- Manage QoS (Quality of Service) priority across network paths
- Route signals between nodes without crossing or congesting paths
- Fix network congestion during peak city demand scenarios

Think Mini Metro meets city builder — not the other way around.

## Architecture
- Backend: ExpressJS + MS SQL (cloud save only, REST API)
- Frontend: Godot 4.7 (mobile-first, Android/iOS export)
- Auth/Cloud: Firebase Authentication + Firestore
- Local save: Godot built-in `user://` save files
- Cloud sync: HTTPRequest node → Express API (background, optional)
- Game works 100% offline — cloud save is a bonus, not a requirement

## AI Systems
- Adaptive Difficulty Engine (GDScript, rule-based, no external API)
  - Tracks player score per level
  - Adjusts bandwidth demand, QoS complexity, and node count
  - Target: keep player in Flow state (not too hard, not too easy)
- Context-sensitive Hint System (Express → OpenAI, online only)
  - Triggered when player fails same puzzle 2+ times
  - Returns a 1-sentence TelCom-flavored hint
  - Falls back to pre-generated Firestore hints when offline

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
- Local save: `user://save_data.json` via Godot's FileAccess
- Cloud save: POST to `/api/save` on Express backend
- On launch: load local first, then sync from cloud if online
- Never block gameplay waiting for cloud sync

## Coding
- Prefer small, reusable scripts
- Don't rewrite existing systems unless necessary
- Explain major changes before making them
- Keep scene organization clean
- One responsibility per script — routing logic ≠ UI logic ≠ save logic

## Scene Structure (suggested)
- Main.tscn
├── GameWorld (Node2D)
│ ├── TileMap (isometric grid)
│ ├── BuildingLayer (Y-sorted)
│ ├── NetworkLayer (wires, signals, QoS visuals)
│ └── UILayer (HUD, bandwidth meters, QoS indicators)
├── AdaptiveDifficultyManager (Autoload)
├── SaveManager (Autoload)
└── HintManager (Autoload)


## Current Goal
Build the basic isometric city grid and allow the player to place buildings.

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