# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Dodge the Creepers** is a 2D arcade game built with Godot Engine 4.6 using GDScript. The player dodges incoming enemies; getting hit ends the game.

## Engine & Build

- **Engine**: Godot 4.6.3 — installed at `C:\Users\orias\Desktop\Godot_v4.6.3-stable_win64.exe`
- **No external build tools** — Godot handles compilation, running, and exporting natively
- **To run the game**: Open the project in the Godot editor and press F5, or use the editor's play button
- **Export targets** (configured in `export_presets.cfg`):
  - Windows Desktop → `./dodge the creepers.exe`
  - Web (HTML5) → `../dodge the creepers.html`
- **No test framework or linter** — validation is done by running the game in the editor

## Architecture

The game uses Godot's scene-based architecture. Each major system is a scene (`.tscn`) paired with a GDScript (`.gd`). All scripts are in `scripts/`, all scenes in `scenes/`, all assets in `assets/`.

### Scene/Script Pairs & Responsibilities

| Scene | Script | Role |
|---|---|---|
| `scenes/main.tscn` | `scripts/main.gd` | Game controller: state machine (new game / game over), mob spawning via `MobTimer`, score tracking via `ScoreTimer`, music/SFX |
| `scenes/player.tscn` | `scripts/player.gd` | `Area2D` node; reads directional input, clamps movement to screen, emits `hit` signal on mob collision |
| `scenes/mob.tscn` | `scripts/mob.gd` | `RigidBody2D`; spawned along `MobPath` curve, randomized speed (150–250 px/s) and animation ("fly"/"swim"/"walk"), self-destructs when off-screen |
| `scenes/hud.tscn` | `scripts/hud.gd` | `CanvasLayer` UI: score label, message display, start button; emits `start_game` signal |

### Signal Flow

```
HUD.start_game  →  Main.new_game()
Player.hit      →  Main.game_over()
Main (ScoreTimer.timeout) → HUD.update_score()
Main (MobTimer.timeout)   → spawns Mob instance
```

### Input Actions (defined in `project.godot`)

- `move_left/right/up/down` → Arrow keys or WASD
- `start_game` → Return key or Space

### Persistence

- High score saved to `user://highscore.dat` via `FileAccess` (32-bit int)
- On Windows: `%APPDATA%\Godot\app_userdata\dodge the creepers\highscore.dat`
- Loaded in `Main._ready()`, saved in `Main.game_over()` when score exceeds previous best
- HUD displays current best as "Best: X" below the live score label
