# Enter-the-Fold
A 2D typing-based laundry store management game built in Godot 4

---

## About the Game

Enter the Fold is a 2D typing and spelling game set in a laundry store. Inspired by the fast-paced style of games like [Overcooked 2](https://store.steampowered.com/app/728880/Overcooked_2/), [PlateUp!](https://store.steampowered.com/app/1599600/PlateUp/) and [The Chef's Shift](https://store.steampowered.com/app/2390230/The_Chefs_Shift), The game starts with a laundromat - where every action is driven by typing words and letters correctly.

The goal is to engage players while genuinely teaching them to type and spell. Every interaction in the store - picking up a laundry basket, loading a machine, placing clean laundry on a shelf, handing it back to the customer - is triggered by typing a predetermined word or letter. The faster and more accurately you type, the more customers you serve, the more money you earn, and the further you progress.

The name carries a double meaning: folding laundry, and pressing the Enter key — the last keystroke before a customer walks out satisfied.

---

## Core Gameplay Loop

Each level represents a single day at the laundry store. The loop for each customer follows these steps:

1. A customer walks in and drops off their laundry
2. The player types a word/letter to pick up the laundry basket
3. The player types a word/letter to load it into a washing machine
4. The player waits for the machine to finish
5. The player types a word/letter to remove the laundry and place it on the shelf
6. The customer returns — the player types a word/letter to serve them and collect payment

All interactions are typing-based. There are no clicks or button presses — only the keyboard.

---

## Difficulty & Progression

### Difficulty Settings
Difficulty controls the number of customers that appear in a single day:

| Setting     | Customers |
|-------------|-----------|
| Very Easy   | Fewest    |
| Easy        | Few       |
| Medium      | Moderate  |
| Hard        | Many      |
| Very Hard   | Most      |

### Game Level Progression
As players advance through levels, the complexity of laundry tasks increases:

- **Early levels** — Washing only
- **Mid levels** — Washing, drying, and ironing
- **Higher levels** — Different laundry types (costumes, sheets, etc.) requiring different machines

Between levels, players can spend earned money to buy additional machines, upgrade to faster machines, purchase better detergent, and unlock other improvements. Better machines reduce wait times and increase throughput.

---

## Economy & Upgrades

Each fully served customer rewards the player with money. This money can be spent on:

- Additional washing, drying, or ironing machines
- Faster/higher-end machines (reduced processing time)
- Better detergent and other performance upgrades

---

## Typing Progression

The difficulty of the typing itself scales with game level:

- Early levels use single letters
- Later levels introduce short words, then longer and more complex words

This gradual progression is central to the educational goal — players naturally build typing skill and spelling ability as they advance.

---

## Planned Features

The game is being developed incrementally, with the following milestones planned:

1. **Core typing loop** — Letters and short words appear on screen; typing them correctly makes them disappear. Placeholder visuals while assets are developed.
2. **Difficulty selection** — Configurable difficulty settings (very easy through very hard) affecting customer volume.
3. **Main menu & level select** — A main menu to choose levels and a settings screen for difficulty.
4. **Characters & store** — Customers walk into the store following fixed paths; words appear above their heads.
5. **Time system** — The store runs from 8am–8pm in-game (12 in-game hours = 3 real minutes). Machine processing times added (low-end machines take ~10 seconds; upgrades reduce this).
6. **Audio** — Background music and sound effects.
7. **Machine breakdowns** — Random machine failures that the player must resolve by typing a repair word.

The current focus is on milestones 1–3: a single-level base game where a customer appears, drops off laundry, the player types through the full service loop, and earns money.
---
