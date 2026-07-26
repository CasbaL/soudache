---
feature: full-game-implementation
status: in-progress
updated: 2026-07-27
---

# Full Game Implementation - 仙侠搜打撤

## Report
(empty - in progress)

## [S1] Problem
The game has design documents for all systems but only a basic prototype. Need to implement all designed features to make the game fully playable.

## [S2] Design

### Core Systems to Implement

1. **Skill System** - Skills with real damage/effects, cooldowns, projectiles
2. **Equipment System** - Equip, enhance, rarity, stat bonuses
3. **Multiple Enemy Types** - All 3 layers with variants
4. **Boss System** - 3 bosses with multi-phase fights
5. **Map Generation** - Procedural room-based maps
6. **Bullet/Barrage System** - Enemy projectiles with warnings
7. **Building System** - Cave dwelling with 9 buildings
8. **UI System** - Complete HUD, menus, damage numbers
9. **Faction System** - 3 schools (Sword, Talisman, Pill)
10. **Fog System** - Map exploration fog

### Architecture
- All systems use GDScript
- Data-driven with JSON configs
- Signal-based communication
- Autoload singletons for global state

## Tasks
- [ ] T1: Skill System — implement 3 skills per faction with projectiles and effects (covers: S2)
- [ ] T2: Equipment System — equip, enhance, rarity, stat application (covers: S2)
- [ ] T3: Enemy Variants — implement all enemy types for 3 layers (covers: S2)
- [ ] T4: Boss System — 3 bosses with phase transitions (covers: S2)
- [ ] T5: Map Generation — procedural room-based map system (covers: S2)
- [ ] T6: Bullet System — enemy projectiles with warning indicators (covers: S2)
- [ ] T7: Building System — 9 buildings with upgrade/craft mechanics (covers: S2)
- [ ] T8: UI System — complete HUD, menus, damage numbers, inventory (covers: S2)
- [ ] T9: Faction System — 3 schools with unique skills and stats (covers: S2)
- [ ] T10: Integration — connect all systems, full game loop (covers: S2)
