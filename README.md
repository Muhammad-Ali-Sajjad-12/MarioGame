# Super Mario Engine — COAL Lab Semester Project

**Course:** EL2003 – Computer Organization and Assembly Language  
**Campus & Section:** FAST-NUCES Chiniot-Faisalabad · BS AI, Section B (Fall 2026)  
**Repository:** `COAL_Project_BAI_B_25F-0105_25F-3032_25F-0119`

A side-scrolling platform game written entirely in 16-bit x86 assembly (NASM), running as a DOS `.COM` program in DOSBox, with VGA mode 13h graphics, our own keyboard and timer interrupt handlers and an off-screen frame buffer.

## 1. Team Members and Modules

| Member | Name | Roll Number | Role | Modules and Files |
| :--- | :--- | :--- | :--- | :--- |
| **Member 1** | [Name] | `25F-0119` | Graphics & Display | **Modules 1, 2, 4, 5, 13:** program skeleton and main loop (`mario.asm`), VGA mode 13h, colours and frame buffer (`video.asm`), sprite drawing and sprite art (`sprite.asm`), 32-bit score, coins, lives and HUD (`hud.asm`) |
| **Member 2** | Muhammad Ali Sajjad | `25F-0105` | World & Hero | **Modules 3, 6, 9, 10, 12:** level map and tile drawing (`map.asm`), camera and scrolling (`camera.asm`), 8.8 fixed-point player physics (`hero.asm`), tile collision, pit, flag and rectangle overlap (`collide.asm`), blocks, coins and mushroom (`items.asm`) |
| **Member 3** | [Name] | `25F-3032` | System & Game Flow | **Modules 7, 8, 11, 14, 15 and bonus sound:** `INT 09h` keyboard and `INT 1Ch` timer handlers (`intr.asm`), Goombas, Koopas and shells (`enemies.asm`), state machine, screens, win, lose and reset (`game.asm`), PC speaker sound effects (`sound.asm`) |

## 2. Build and Run (DOSBox 0.74-3 + NASM 0.98.38)

Inside DOSBox, mount the project folder and the folder that holds `nasm.exe` (change the paths to yours), then build from inside `src`:

```dos
mount c D:\Mario
mount t D:\AFD&NASM
path t:\
c:
cd \src
nasm -O2 mario.asm -o mario.com
mario
```

`build.bat` in the project root does the same build. The `-O2` option is required with NASM 0.98.38 so that long conditional jumps are assembled correctly. For full speed, set `cycles=max` in the DOSBox options.

The `tests` folder holds the small test programs we used to check each module on its own before joining them.

## 3. Controls (Appendix A.3)

| Key | Scan Code | Action |
| :--- | :--- | :--- |
| **Left / Right Arrow** | `4Bh` / `4Dh` | Move Mario |
| **Left Shift** | `2Ah` | Hold to run |
| **Space** | `39h` | Jump (hold for a higher jump, release early for a short hop) |
| **Up / Down Arrow** | `48h` / `50h` | Move the highlight on the title screen |
| **Enter** | `1Ch` | Select on the title screen, continue on the Level Complete and Game Over screens |
| **P** | `19h` | Pause and resume |
| **Esc** | `01h` | Back to the title screen while playing or paused, exit to DOS from the title screen |

## 4. Memory Choices

* **One segment for the program:** as a `.COM` program, our code, data and stack share one 64 KB segment, starting at offset `100h`.
* **Frame buffer in a second segment:** the 320 × 200 picture needs 64,000 bytes, which cannot fit beside the program in the same segment. At start-up, `InitBuffer` (`video.asm`) first shrinks our own memory block to 64 KB with DOS function `4Ah`, then asks DOS for 4000 paragraphs (64,000 bytes) with function `48h`. The segment DOS returns is stored in `bufferSeg`. Every frame is cleared with `REP STOSW`, drawn in that buffer, and copied to video memory at `0A000h` with one `REP MOVSW` during the vertical retrace, so there is no flicker or tearing.
* **Two copies of the level map:** the 60 × 12 tile map (720 bytes, one byte per tile) is kept as an original copy that never changes and a working copy where bricks break and coins disappear. On every new life and new game, `ResetMap` copies the original over the working copy with `REP MOVSB`. The enemy table is restored the same way with `REP MOVSW`.

## 5. Game States (Section 5.12)

The main loop calls `UpdateGameState`, which jumps through a word table (`stateTable` in `game.asm`) indexed by `gameState`:

* **0 – TITLE:** game name, `START GAME` and `EXIT` with a highlight bar (Up / Down and Enter) and our roll numbers. Esc also exits.
* **1 – PLAYING:** each frame follows Section 5.13: update Mario (physics and tile collision), camera, enemies and items; resolve stomps, damage, kicks, coins and the mushroom; count the clock and the invulnerability timer; check death and the flag pole; draw the map, items, enemies, Mario and the HUD.
* **2 – PAUSED:** P freezes everything, including the clock, and shows `PAUSED` over the level. P resumes, Esc returns to the title.
* **3 – DYING:** about 1.5 s. Enemies and the clock are frozen while Mario hops and falls (no hop after a pit), then one life is taken.
* **4 – LIFE LOST:** about 2 s. Shows the world name, a Mario icon and the lives left, then restarts the level.
* **5 – WIN SEQUENCE:** after the flag pole is touched, the flag points are added, Mario slides down the pole and walks on for about 1 s each, and the time left × 50 is added to the score.
* **6 – LEVEL COMPLETE:** shows the score, coins and time left until Enter returns to the title.
* **7 – GAME OVER:** shown when the last life is lost, with the final score. Enter returns to the title.
* **8 – EXIT:** the main loop ends: the speaker is silenced, the original `INT 09h` and `INT 1Ch` vectors and the normal timer rate are restored, the screen returns to text mode and the program exits to DOS.

## 6. Debug Keys

None. The game has no debug keys.

## 7. Deviations, Bonus Features and Known Limitations

**Deviations**
* **Timer at 30 ticks per second:** the timer chip (PIT channel 0) is set to about 30 Hz (divisor 39772) instead of the default 18.2 Hz, so that the physics constants of Appendix A.5, which are given per frame at 30 frames per second, can be used unchanged. The normal rate is restored on exit.
* **Tiles as coloured blocks:** map tiles are drawn as coloured squares with a darker edge instead of bitmap pictures, to keep `DrawMap` fast and simple. Mario, the enemies, the mushroom and the coins use our own sprite art.

**Bonus features**
* **Sound effects:** PC speaker tones through PIT channel 2 (ports `43h`, `42h` and `61h`) for jump, coin, block bump, brick break, mushroom, stomp, shell kick, 1-UP, flag and death. Each tone plays for a few frames and then stops.
* **Walking animation:** while Mario runs, his standing and walking pictures alternate every 4 frames.

**Known limitations**
* Sounds are single short tones; there is no background music.
* Only one mushroom can be in the level at a time. If a second mushroom block is hit while a mushroom is still moving, the new one replaces it.
* While the game runs, the DOS clock advances faster because of the 30 Hz timer. It is correct again after the game exits.