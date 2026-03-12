# Enter-the-Fold
A 2D typing-based laundry store management game built in Godot 4.6

---

## About the Game

Enter the Fold is a 2D typing and spelling game set in a laundry store. Inspired by the fast-paced style of games like [Overcooked 2](https://store.steampowered.com/app/728880/Overcooked_2/), [PlateUp!](https://store.steampowered.com/app/1599600/PlateUp/) and [The Chef's Shift](https://store.steampowered.com/app/2390230/The_Chefs_Shift), the game starts with a laundromat — where every action is driven by typing words and letters correctly.

The goal is to engage players while genuinely teaching them to type and spell. Every interaction in the store — picking up a laundry basket, collecting clean laundry from a machine, handing it back to the customer — is triggered by typing a word. The faster and more accurately you type, the more customers you serve, the more money you earn, and the further you progress.

The name carries a double meaning: folding laundry, and pressing the Enter key — the last keystroke before a customer walks out satisfied.

---

## Current State — Playable Prototype (Sprint 3)

The game is now a **fully integrated, playable Level 1 prototype**. All frontend scenes and backend systems from Sprints 2 and 3 have been wired together into a single gameplay loop.

### What's Working

- **Full customer service loop** — Customers walk in, drop off laundry, wait while it washes, return to pick it up, and leave after being served.
- **Up to 3 simultaneous customers** — Multiple customers can be on screen at once, each independently progressing through the service pipeline. The max concurrent count scales with difficulty.
- **Typing-driven interactions** — Every action (pickup, machine collect, serve) is triggered by typing the displayed word correctly. Word prompts appear above the relevant game object with a dark backdrop for visibility.
- **3 washing machines** — Machines operate independently with a 10-second wash cycle. Clean laundry prompts appear above the machine when done.
- **Day timer** — The store runs from 8:00 AM to 8:00 PM (180 real seconds). Customers keep arriving until the day ends.
- **HUD** — Displays current money, time of day, customers served, and a task hint.
- **End-of-day summary** — Shows total money earned and customers served, with a button to return to the main menu.
- **Settings screen** — Configurable customer difficulty, word difficulty, music volume, and SFX volume. All settings persist to disk.
- **Scene flow** — Main Menu → Level Select → Laundry Store, with a pause menu (Escape key) and scene transitions.
- **Background music** — Plays on the Music audio bus with adjustable volume.

---

## Core Gameplay Loop

Each level represents a single day at the laundry store. Multiple customers can be active simultaneously, each following this pipeline:

1. A customer walks in and stands at a drop-off station
2. A word prompt appears — type it to **pick up** the laundry
3. The laundry goes into a washing machine (10-second wash cycle); the customer leaves temporarily
4. When the machine finishes, a word prompt appears above it — type it to **collect** the clean laundry
5. The laundry is placed on the shelf; after 5 seconds the customer returns to the counter
6. A word prompt appears — type it to **serve** the customer and collect $10

All interactions are typing-based. There are no clicks or button presses — only the keyboard.

---

## Difficulty & Settings

### Customer Difficulty
Controls how many customers can be on screen simultaneously and how frequently they arrive:

| Setting   | Max Concurrent | Spawn Delay |
|-----------|---------------|-------------|
| Very Easy | 1             | 20s         |
| Easy      | 2             | 14s         |
| Medium    | 3             | 10s         |
| Hard      | 3             | 7s          |
| Very Hard | 3             | 5s          |

There is no fixed customer-per-day limit — customers keep arriving while the day timer runs.

### Word Difficulty
Controls the complexity of words the player must type:

| Setting   | Word Pool                          |
|-----------|------------------------------------|
| Very Easy | Single letters (a–z)               |
| Easy      | Short words (3–4 letters)          |
| Medium    | Short words (3–4 letters)          |
| Hard      | Medium words (6–7 letters)         |
| Very Hard | Long words (7–9 letters)           |

Both settings default to **Medium** and can be changed from the Settings screen.

### Audio
Music and SFX volumes are adjustable via sliders in the Settings screen (-40 dB to +6 dB). Dragging to minimum mutes the bus entirely. Settings persist across sessions.

---

## Architecture

### Autoloads
| Name         | Purpose                                           |
|--------------|---------------------------------------------------|
| GameState    | Tracks money, score, and persistent game data      |
| GameConfig   | Stores difficulty settings (customer + word)        |
| SceneRouter  | Handles scene transitions                          |
| SceneFader   | Fade-in/fade-out visual transitions                |
| Music        | Background music (AudioStreamPlayer on Music bus)  |

### Key Scripts
| Script                    | Role                                                    |
|---------------------------|---------------------------------------------------------|
| `LaundryGameManager.gd`  | Central orchestrator — spawns customers, manages phases, coordinates prompts and machines |
| `PromptManager.gd`       | Creates and tracks WordPrompt instances, provides random words from the word list |
| `TypingManager.gd`       | Handles keyboard input, matches characters to active word prompts |
| `WordPrompt.gd`          | Displays a word above an anchor node, tracks typed progress |
| `customer.gd` / `customer_2.gd` / `customer_3.gd` | Customer movement and animation (walk to position, idle, leave) |
| `washing_machine.gd`     | Washing machine state (idle → washing → done), emits `wash_complete` |
| `daytimer.gd`            | In-game clock (8 AM–8 PM in 180 real seconds)           |
| `GameHUD.gd`             | HUD overlay showing money, time, customers served, task hints |
| `Settings.gd`            | Settings screen with difficulty dropdowns and volume sliders |

### Scene Tree (LaundryStore.tscn)

```
LaundryStore (Node2D + LaundryGameManager.gd)
  ├── TileMap                    — Environment tiles (floor, walls, furniture)
  ├── Markers (Node2D)           — Spatial anchor points
  │     ├── CustomerEntrance     — Where customers spawn
  │     ├── DropOffPoint         — Laundry drop-off station (base position)
  │     ├── ShelfSlot_1          — Laundry shelf
  │     ├── PickupCounter        — Customer pickup counter
  │     ├── CameraRoot           — Camera reference point
  │     └── WashingMachine       — Original machine marker (replaced at runtime by 3 instances)
  ├── LaundryPlayer (CharacterBody2D)
  │     ├── AnimatedSprite2D     — Player character (idle, no movement)
  │     └── Camera2D             — 4x zoom, position smoothing
  ├── UI (CanvasLayer)
  │     ├── GameHUD              — In-game HUD (money, time, task, day-over panel)
  │     └── PauseMenu            — Escape to pause
  ├── Machine_0, Machine_1, Machine_2  — Washing machines (spawned at runtime)
  ├── PromptManager              — Word prompt system (spawned at runtime)
  │     └── TypingManager        — Keyboard input handler
  ├── DayTimer                   — In-game day clock (spawned at runtime)
  └── Customer_N                 — Active customers (spawned/freed dynamically)
```

Target resolution: 1920×1080 landscape, stretch mode `canvas_items`, Mobile renderer.

---

## Economy & Upgrades (Planned)

Each fully served customer rewards the player with $10. This money will eventually be spendable on:

- Additional washing, drying, or ironing machines
- Faster machines (reduced processing time)
- Better detergent and other performance upgrades

---

## Planned Features

1. ~~Core typing loop~~ ✅
2. ~~Difficulty selection~~ ✅
3. ~~Main menu & level select~~ ✅
4. ~~Characters & store~~ ✅
5. ~~Time system~~ ✅
6. ~~Audio~~ ✅
7. **Machine breakdowns** — Random machine failures requiring a repair word
8. **Multiple levels** — Progressive difficulty with new machine types (dryers, irons)
9. **Upgrade shop** — Spend earned money between levels
10. **Portrait mode** — Custom on-screen keyboard for mobile
