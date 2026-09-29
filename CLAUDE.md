# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Dodge the Creepers** is a 2D arcade game built with Godot Engine 4.7 using GDScript. The player dodges incoming enemies; getting hit ends the game.

## Engine & Build

- **Engine**: Godot 4.7.2
- **No external build tools** — Godot handles compilation, running, and exporting natively
- **To run the game**: Open the project in the Godot editor and press F5, or use the editor's play button
- **Export targets** (configured in `export_presets.cfg`):
  - Windows Desktop → `./dodge the creepers.exe`
  - Web (HTML5) → `../dodge the creepers.html`
- **No test framework** — gameplay validation is done by running the game in the editor
- **Lint/format**: [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit) (`gdlint` + `gdformat`), pinned in `.pre-commit-config.yaml` and enforced in CI
  - One-time setup per clone: install pre-commit (`pipx install pre-commit`, `uv tool install pre-commit`, or `pip install pre-commit`), then `pre-commit install`
  - Run manually: `pre-commit run --all-files` (or `gdformat scripts/` / `gdlint scripts/`)
  - If the hook reformats a file, the commit is aborted — re-stage and commit again

## CI/CD (GitHub Actions)

- **CI** (`.github/workflows/ci.yml`, on pull requests): `pre-commit run --all-files` (gdformat + gdlint), and a headless Godot Web export smoke test
- **CD** (`.github/workflows/cd.yml`, on push to `main`): bumps the `vX.Y` tag, writes it to `application/config/version`, exports Web, and publishes a GitHub Release
- Both workflows install Godot via `chickensoft-games/setup-godot` — keep its `version` in sync with the engine version above when upgrading

## Architecture

The game uses Godot's scene-based architecture. Each major system is a scene (`.tscn`) paired with a GDScript (`.gd`). All scripts are in `scripts/`, all scenes in `scenes/`, all assets in `assets/`.

Code is strictly typed: `project.godot` enables the `untyped_declaration`, `inferred_declaration` and `unsafe_*` GDScript warnings. Scripts that other scripts call into declare a `class_name` (`HUD`, `Player`, `PowerUp`), and child nodes are accessed through typed `@onready var` references rather than bare `$Node` calls, so no warnings fire.

### Scene/Script Pairs & Responsibilities

| Scene | Script | Role |
|---|---|---|
| `scenes/main.tscn` | `scripts/main.gd` | Game controller: state machine (new game / game over), mob spawning via `MobTimer`, score tracking via `ScoreTimer`, power-up spawning via `PowerUpTimer`, banked/standby power-up state, music/SFX |
| `scenes/player.tscn` | `scripts/player.gd` | `Area2D` node; reads directional input, clamps movement to a reserved play area, handles timed invincibility (blink tween), emits `hit` signal on mob collision |
| `scenes/mob.tscn` | `scripts/mob.gd` | `RigidBody2D`; spawned along `MobPath` curve, randomized speed (150–250 px/s) and animation ("fly"/"swim"/"walk"), self-destructs when off-screen |
| `scenes/power_up.tscn` | `scripts/power_up.gd` | `Area2D`; randomly-typed pickup (`INVINCIBILITY` or `CLEAR_MOBS`), emits `collected` on player pickup or `expired` via `DespawnTimer` if not collected in time |
| `scenes/hud.tscn` | `scripts/hud.gd` | `CanvasLayer` UI: score/high-score labels, message display, start/quit buttons, active power-up slot indicator; emits `start_game` and `quit_game` signals |

### Power-ups (banked/active system)

- `PowerUpTimer` spawns one `power_up.tscn` instance at a time within the play area; it only restarts once that pickup is collected or expires (via `DespawnTimer`)
- Collecting a pickup doesn't apply its effect immediately — it's banked as `standby_effect` and shown in the HUD's active slot
- Pressing the `use_power_up` action consumes the banked effect: `INVINCIBILITY` calls `Player.set_invincible()`, `CLEAR_MOBS` frees all nodes in the `"mobs"` group
- The play area is inset from the full viewport by `TOP_BAR_HEIGHT`/`BOTTOM_BAR_HEIGHT` in `main.gd`, reserving top/bottom bars for score and the power-up slot UI

### Signal Flow

```
HUD.start_game     →  Main.new_game()
HUD.quit_game       →  Main._on_hud_quit_game()  (get_tree().quit())
Player.hit          →  Main.game_over()
PowerUp.collected   →  Main._on_power_up_collected()  →  HUD.show_active_power_up()
PowerUp.expired     →  Main._on_power_up_expired()  →  restarts PowerUpTimer
Main (ScoreTimer.timeout)    → HUD.update_score()
Main (MobTimer.timeout)      → spawns Mob instance
Main (PowerUpTimer.timeout)  → spawns PowerUp instance
```

### Input Actions (defined in `project.godot`)

- `move_left/right/up/down` → Arrow keys or WASD
- `start_game` → Return key or Space
- `use_power_up` → Shift (activates the banked power-up)

### Persistence

- High score saved to `user://highscore.dat` via `FileAccess` (32-bit int)
- On Windows: `%APPDATA%\Godot\app_userdata\dodge the creepers\highscore.dat`
- Loaded in `Main._ready()`, saved in `Main.game_over()` when score exceeds previous best
- HUD displays current best as "Best: X" below the live score label

### Web Export Notes

- `hud.gd` checks `OS.has_feature("web")` and hides the quit button on web builds (browser tabs can't be closed programmatically)
- HUD shows the game version (from `application/config/version` in `project.godot`) on the start screen
