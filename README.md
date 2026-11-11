# Super Mario Engine — COAL Lab Semester Project

**Course:** EL2003 – Computer Organization and Assembly Language  
**Campus & Section:** FAST-NUCES Chiniot-Faisalabad · BS AI, Section B (Fall 2026)  
**Repository:** `COAL_Project_BAI_B_25F-0105_25F-3032_25F-0119`

## 1. Team Members and Modules

| Member | Roll Number | Role | Assigned Modules & Files |
| :--- | :--- | :--- | :--- |
| **Member 1** | `25F-0119` | Graphics & Display | **Modules 1, 2, 4, 5, 13:** Program skeleton (`mario.asm`), VGA Mode 13h & frame buffer (`video.asm`), sprite rendering (`sprite.asm`), 32-bit score & HUD (`hud.asm`) |
| **Member 2** (Muhammad Ali Sajjad) | `25F-0105` | World & Hero | **Modules 3, 6, 9, 10, 12:** Level map & tiles (`map.asm`), camera scrolling (`camera.asm`), 8.8 fixed-point physics (`hero.asm`), tile & entity collisions (`collide.asm`), blocks, coins & mushroom (`items.asm`) |
| **Member 3** | `25F-3032` | System & Game Flow | **Modules 7, 8, 11, 14, 15 (+ Bonus Sound):** Custom `INT 09h` keyboard & `INT 1Ch` timer handlers (`intr.asm`), Goomba, Koopa & shell logic (`enemies.asm`), state machine, screens, win/lose sequences & reset (`game.asm`), PC speaker sound effects (`sound.asm`) |

## 2. Build and Run Steps (DOSBox 0.74-3 + NASM 0.98.38)

Mount the project directory and the NASM folder inside DOSBox, then assemble from inside `src`:

```dos
mount c D:\Mario
mount t D:\AFD&NASM
path t:\
c:
cd \src
nasm -O2 mario.asm -o mario.com
mario
```

You can also run `build.bat` from the project root inside DOSBox.

## 3. Game Controls (Appendix A.3)

| Key | Scan Code | Action |
| :--- | :--- | :--- |
| **Left Arrow** | `4Bh` | Move Mario left |
| **Right Arrow** | `4Dh` | Move Mario right |
| **Up / Down Arrow** | `48h` / `50h` | Move highlight in the Title menu |
| **Space Bar** | `39h` | Jump (hold longer for higher jump, release early for short hop) |
| **Left Shift** | `2Ah` | Hold to run faster |
| **P** | `19h` | Pause / resume game |
| **Enter** | `1Ch` | Confirm selection on Title, Level Complete, and Game Over screens |
| **Esc** | `01h` | Return to Title screen from gameplay, or exit to DOS from Title |

## 4. Memory Architecture and Frame Buffer

* **Single-Segment `.COM` Program:** Code, data, and stack share the primary 64 KB segment starting at `ORG 100h`.
* **Off-Screen Frame Buffer (64,000 Bytes):** Because a 320 × 200 screen buffer (64,000 bytes) cannot fit inside the same 64 KB segment as the program code and data, a second segment is reserved for the off-screen frame buffer (`InitBuffer` in `video.asm`). Every frame is cleared with `REP STOSW`, drawn into the off-screen segment, and copied to VGA memory (`0A000h`) in one block move (`REP MOVSW`) to prevent flicker.
* **Two Copies of the Level Map:** The 60 × 12 tile map (720 bytes) is kept in two arrays: an unchanged original copy and a working copy where bricks break and coins are collected. On every new life or new game, `ResetMap` restores the working map from the original copy using `REP MOVSB`.

## 5. Game States (Section 5.12)

The main loop dispatches execution through a word jump table (`stateTable` in `game.asm`) indexed by `gameState`:

* **0 – TITLE (`stateTitle`):** Shows the title screen with `START GAME` and `EXIT` options controlled by Up/Down and Enter.
* **1 – PLAYING (`statePlaying`):** Runs the 10-step frame update order: reads `key_table`, updates Mario physics and tile collisions, updates camera, updates enemies and items, counts down the 1-second clock and invulnerability timer, checks death/flagpole conditions, and draws the frame.
* **2 – PAUSED (`statePaused`):** Freezes all movement and timers when `P` is pressed while keeping the level visible with a pause box. Pressing `P` resumes; `Esc` returns to Title.
* **3 – DYING (`stateDying`):** Freezes enemies and clock for 1.5 seconds while Mario plays the death hop/fall animation, then decrements `lives`.
* **4 – LIFE LOST (`stateLifeLost`):** Displays remaining lives for 2 seconds when `lives > 0`, calls `ResetLevel`, and returns to `PLAYING`.
* **5 – WIN SEQUENCE (`stateWinSeq`):** Triggered when Mario touches the flagpole. Awards height points, slides Mario down the pole for 1 second, walks him toward the castle for 1 second, and adds `gameTime × 50` bonus points.
* **6 – LEVEL COMPLETE (`stateLevelDone`):** Displays the final level complete summary until `Enter` is pressed to return to `TITLE`.
* **7 – GAME OVER (`stateGameOver`):** Shown when `lives` reaches 0. Pressing `Enter` returns to `TITLE`.
* **8 – EXIT (`stateExit`):** Restores original `INT 09h` and `INT 1Ch` interrupt vectors, returns the display to 80 × 25 text mode (`INT 10h, AX=0003h`), and exits cleanly to DOS (`INT 21h, AH=4Ch`).

## 6. Bonus Features, Deviations, and Limitations

* **Bonus Feature Implemented:** PC speaker sound effects (`src/sound.asm`) using PIT Channel 2 (ports `43h`, `42h`, and `61h`) for jump, coin, stomp, shell kick, power-up, 1-UP, brick break, and death events.
* **Deviations:** None. All scoring tables, 8.8 fixed-point physics constants, enemy behaviours, and screen transitions follow Section 5 and Appendix A of the project manual.
* **Known Limitations:**
  * The level is 12 tiles (192 pixels) tall with no vertical camera scrolling, as specified in Section 5.3.
  * Up to 8 enemies are active at once to maintain a steady 30 FPS frame rate in DOSBox.
  * PC speaker audio plays single-channel square-wave tones due to standard 8254 hardware limits.
