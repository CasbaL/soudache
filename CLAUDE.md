# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Godot 4.x GDScript mobile game (iOS/Android) with a Chinese xianxia (cultivation/immortal) theme. Core gameplay loop is "Search-Fight-Extract" (搜打撤) — explore maps, fight enemies, collect resources, extract with loot, and build up a permanent base.

- **Engine:** Godot 4.7 (renderer: `gl_compatibility` for mobile)
- **Language:** GDScript exclusively (no C#)
- **Viewport:** 720×1280 portrait, pixel art (nearest filter)
- **Target:** iOS (arm64) and Android (arm64-v8a, armeabi-v7a)

## Commands

```bash
# Run the game (from project root)
godot --path .

# Run tests (headless, exit code 0 = pass, 1 = fail)
godot --headless --path . scenes/tests/test_comprehensive.tscn

# Generate sprite assets (requires Python + Pillow)
python tools/create_game_assets.py
python tools/generate_sprites.py
```

No Makefile, npm, or other build tools — everything runs through the Godot editor (F5) or CLI.

## Architecture

### Autoload Singletons (18 total)

All major systems are registered as Godot autoloads in `project.godot` and accessed by name (e.g., `GameManager`, `EquipmentSystem`).

**Core Managers** (`scripts/autoload/`):
- `GameManager` — Game state machine (MENU/PLAYING/PAUSED/GAME_OVER/VICTORY), player data, inventory (max 10 slots), persistent storage, extraction logic
- `AudioManager` — BGM with fade, SFX player pool (10 concurrent)
- `SaveManager` — Binary save at `user://savegame.dat` with version migration and backup

**Game Systems** (`scripts/systems/`):
- `FactionSystem` — 3 factions: sword, talisman, pill
- `SkillSystem` — Skill data from JSON, cooldowns, DOTs, shields, projectiles
- `EquipmentSystem` — 5 slots (weapon/armor/helmet/accessory×2), stat aggregation, set bonuses
- `EnhanceSystem` — Equipment enhancement +1 to +15 with decreasing success rates
- `BuildingSystem` — 9 buildings, 5-level upgrades, resource costs
- `RealmSystem` — 5 cultivation realms (炼气→化神), stat bonuses, breakthrough
- `TechniqueSystem` — Learnable passive/active techniques
- `EnemySpawner` — Loads enemy data from JSON, spawns per layer
- `AlchemySystem`, `CraftingSystem`, `ShopSystem`, `PortalSystem`, `FarmSystem`, `TreasureVaultSystem`, `NPCInteractionSystem`, `CombatFeedback`

### Data-Driven Design

Game data lives in `data/` as JSON files:
- `enemies.json` — Enemy stats per layer (3 layers)
- `equipment.json` — Equipment templates
- `skills.json` — Skills per faction
- `factions.json` — Faction definitions

Systems load and parse these at runtime rather than hardcoding data.

### Non-Autoload Systems

Instantiated as needed (use `class_name` for type access):
- `MapGenerator` (RefCounted) — Procedural room-based map generation with main path + branches
- `MapRenderer`, `RoomManager`, `RoomTemplates`, `Room` — Room layout and rendering
- `BulletPool`, `Bullet`, `BulletPatterns` — Bullet/barrage system
- `FactionData`, `EquipmentData`, `EquipmentGenerator`, `SetBonusData`, `BuildingData` — Static data classes

### Communication Pattern

Systems emit signals for state changes (e.g., `equipment_changed`, `inventory_changed`, `game_state_changed`). Most systems implement `serialize()`/`deserialize()` for save/load support.

### Physics Layers

6 layers defined in project.godot: player, enemies, resources, walls, projectiles, enemy_bullets. 2D gravity is 0 (top-down game).

## Input Map

- **Movement:** WASD (also arrow keys)
- **Skills:** 1, 2, 3
- **Dodge:** Space
- **Ultimate:** R

## Test Framework

Custom built-in (no third-party framework). Tests use `_check()`, `_check_eq()`, `_check_range()`, `_begin_suite()`, `_end_suite()` helpers. Main test suite in `tests/test_comprehensive.gd` covers 19 test suites (~1480 lines).

## Design Documents

Root-level `.md` files are Chinese design docs covering combat, building, equipment, maps, bosses, and technical architecture.
