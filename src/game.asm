; Modules 14 and 15: Game States, Screens, Win, Lose, and Reset (Member 3)

; State constants
stateTitle          equ 0
statePlaying        equ 1
statePaused         equ 2
stateDying          equ 3
stateLifeLost       equ 4
stateWinSeq         equ 5
stateLevelDone      equ 6
stateGameOver       equ 7
stateExit           equ 8

; Extra scan codes for menus and pause
keyEsc              equ 01h
keyP                equ 19h
keyEnter            equ 1Ch
keyUp               equ 48h
keyDown             equ 50h

; Game flow limits (at 30 ticks per second)
ticksPerSec         equ 30
startTime           equ 300
startLives          equ 3
dyingTicks          equ 45          ; 1.5 seconds
lifeLostTicks       equ 60          ; 2.0 seconds
winSeqTicks         equ 60          ; 2.0 seconds
flagBaseY           equ 160         ; y of the ground under the flag pole (top of row 10)

; Game state variables
gameState           dw stateTitle
menuChoice          db 0            ; 0 = START GAME, 1 = EXIT
subSecTicks         db 0            ; counts 0..29 for 1-second clock
gameTime            dw startTime
stateTimer          dw 0
pKeyLatch           db 0            ; prevents rapid toggle when holding P
enterKeyLatch       db 0
escKeyLatch         db 0            ; Esc must be released before it works again

; Jump table indexed by gameState
stateTable:
    dw DoTitleState
    dw DoPlayingState
    dw DoPausedState
    dw DoDyingState
    dw DoLifeLostState
    dw DoWinSeqState
    dw DoLevelDoneState
    dw DoGameOverState
    dw DoExitState

; UpdateGameState
; Purpose: Dispatch current frame to the active state handler via stateTable
; Inputs: None
; Outputs: Updates gameState and screen
; Registers changed: None
UpdateGameState:
    push ax
    push bx

    mov bx, [gameState]
    shl bx, 1
    call [stateTable + bx]

    pop bx
    pop ax
    ret

; NewGame
; Purpose: Initialize score, coins, lives, and level for a fresh game
; Inputs: None
; Outputs: All game and level state reset
; Registers changed: None
NewGame:
    push ax

    mov word [scoreLo], 0
    mov word [scoreHi], 0
    mov byte [coins], 0
    mov word [lives], startLives
    mov byte [marioForm], formSmall
    mov byte [marioHp], 1
    mov word [marioHeight], heightSmall
    call ResetLevel

    pop ax
    ret

; ResetLevel
; Purpose: Reset map, enemies, camera, Mario, and clock for a new life
; Inputs: None
; Outputs: Level restored to start state
; Registers changed: None
ResetLevel:
    push ax

    call ResetMap
    call ResetHero
    call ResetEnemies
    call ResetItems

    mov word [cameraX], 0
    mov word [gameTime], startTime
    mov byte [subSecTicks], 0
    mov byte [invulnTimer], 0
    mov byte [stompChain], 0

    pop ax
    ret

; TriggerMarioDeath
; Purpose: Start the death animation and switch to stateDying
; Inputs: None
; Outputs: gameState = stateDying, stateTimer = dyingTicks
; Registers changed: None
TriggerMarioDeath:
    push ax

    cmp word [gameState], stateDying
    je .done

    mov word [gameState], stateDying
    mov word [stateTimer], dyingTicks
    mov word [marioVX], 0
    mov byte [marioPose], poseJump

    ; hop upward unless Mario fell into a pit
    mov word [marioVY], 0
    cmp byte [marioDead], deathPit
    je .sound
    mov word [marioVY], -0400h

.sound:
    call SoundDeath

.done:
    pop ax
    ret

; 0. TITLE STATE
DoTitleState:
    ; Up / Down arrow moves menu highlight
    cmp byte [key_table + keyUp], 1
    jne .check_down
    mov byte [menuChoice], 0
.check_down:
    cmp byte [key_table + keyDown], 1
    jne .check_esc
    mov byte [menuChoice], 1

.check_esc:
    cmp byte [key_table + keyEsc], 1
    je .esc_held
    mov byte [escKeyLatch], 0
    jmp .check_enter
.esc_held:
    ; ignore an Esc that is still held from leaving the game
    cmp byte [escKeyLatch], 1
    je .check_enter
    mov word [gameState], stateExit
    ret

.check_enter:
    cmp byte [key_table + keyEnter], 1
    je .enter_pressed
    mov byte [enterKeyLatch], 0
    jmp .draw_title

.enter_pressed:
    cmp byte [enterKeyLatch], 1
    je .draw_title
    mov byte [enterKeyLatch], 1

    cmp byte [menuChoice], 1
    je .choose_exit

    call NewGame
    mov word [gameState], statePlaying
    ret

.choose_exit:
    mov word [gameState], stateExit
    ret

.draw_title:
    call DrawTitleScreen
    ret

; 1. PLAYING STATE (Section 5.13 frame order)
DoPlayingState:
    ; check Esc -> return to Title
    cmp byte [key_table + keyEsc], 1
    jne .check_pause
    mov byte [key_table + keyEsc], 0
    mov byte [escKeyLatch], 1
    mov word [gameState], stateTitle
    ret

.check_pause:
    cmp byte [key_table + keyP], 1
    je .p_held
    mov byte [pKeyLatch], 0
    jmp .run_updates

.p_held:
    cmp byte [pKeyLatch], 1
    je .run_updates
    mov byte [pKeyLatch], 1
    mov word [gameState], statePaused
    ret

.run_updates:
    ; step 3 & 4: update Mario, camera, items, and enemies
    call UpdateMario
    call UpdateCamera
    call UpdateEnemies
    call UpdateItems

    ; step 6a: decrease invulnerability timer if active
    cmp byte [invulnTimer], 0
    je .update_clock
    dec byte [invulnTimer]

.update_clock:
    ; step 6b: count down 1 second every 30 timer ticks
    inc byte [subSecTicks]
    cmp byte [subSecTicks], ticksPerSec
    jb .check_status
    mov byte [subSecTicks], 0

    cmp word [gameTime], 0
    je .time_up
    dec word [gameTime]
    cmp word [gameTime], 0
    jne .check_status

.time_up:
    call TriggerMarioDeath
    jmp .draw_play

.check_status:
    ; step 7a: check if Mario fell into a pit or died
    cmp byte [marioDead], deathNone
    je .check_flag
    call TriggerMarioDeath
    jmp .draw_play

.check_flag:
    ; step 7b: check if Mario touched the flag pole
    cmp byte [flagTouched], 0
    je .draw_play

    call GetFlagPoints
    push ax
    call AddScore
    mov word [gameState], stateWinSeq
    mov word [stateTimer], winSeqTicks
    mov word [marioVX], 0
    mov word [marioVY], 0

.draw_play:
    ; step 9: draw world, entities, and HUD into frame buffer
    call DrawMap
    call DrawItems
    call DrawEnemies
    call DrawMario
    call DrawHUD
    ret

; 2. PAUSED STATE
DoPausedState:
    cmp byte [key_table + keyEsc], 1
    jne .check_unpause
    mov byte [key_table + keyEsc], 0
    mov byte [escKeyLatch], 1
    mov word [gameState], stateTitle
    ret

.check_unpause:
    cmp byte [key_table + keyP], 1
    je .p_pressed
    mov byte [pKeyLatch], 0
    jmp .draw_pause

.p_pressed:
    cmp byte [pKeyLatch], 1
    je .draw_pause
    mov byte [pKeyLatch], 1
    mov word [gameState], statePlaying
    ret

.draw_pause:
    call DrawMap
    call DrawItems
    call DrawEnemies
    call DrawMario
    call DrawHUD
    call DrawPauseBox
    ret

; 3. DYING STATE (Section 5.8)
DoDyingState:
    ; apply gravity to Mario during death hop/fall (no tile collisions)
    cmp byte [marioDead], deathPit
    je .count_dying

    mov ax, [marioVY]
    add ax, gravity
    cmp ax, maxFall
    jle .save_vy
    mov ax, maxFall
.save_vy:
    mov [marioVY], ax
    sar ax, 8
    add [marioY], ax

.count_dying:
    dec word [stateTimer]
    jnz .draw_dying

    ; animation finished: lose 1 life
    cmp word [lives], 0
    je .no_lives
    dec word [lives]

    cmp word [lives], 0
    je .no_lives

    mov word [gameState], stateLifeLost
    mov word [stateTimer], lifeLostTicks
    ret

.no_lives:
    mov word [gameState], stateGameOver
    mov byte [enterKeyLatch], 1
    ret

.draw_dying:
    call DrawMap
    call DrawItems
    call DrawEnemies
    call DrawMario
    call DrawHUD
    ret

; 4. LIFE LOST STATE (2 seconds)
DoLifeLostState:
    call DrawLifeLostScreen

    dec word [stateTimer]
    jnz .done
    call ResetLevel
    mov word [gameState], statePlaying
.done:
    ret

; 5. WIN SEQUENCE STATE (Section 5.11)
DoWinSeqState:
    ; first 30 ticks: slide down flag pole to base
    cmp word [stateTimer], 30
    jbe .walk_castle

    ; Mario's top when his feet are on the ground (works for Small and Super)
    mov bx, flagBaseY
    sub bx, [marioHeight]
    cmp [marioY], bx
    jge .at_base
    add word [marioY], 4            ; slides the whole pole in about 1 s
    jmp .tick_win
.at_base:
    mov [marioY], bx
    jmp .tick_win

.walk_castle:
    ; last 30 ticks: walk right towards castle
    add word [marioX], 1

.tick_win:
    dec word [stateTimer]
    jnz .draw_win

    ; convert remaining time to bonus points (time * 50)
    mov ax, [gameTime]
    mov bx, 50
    mul bx
    push ax
    call AddScore

    mov word [gameState], stateLevelDone
    mov byte [enterKeyLatch], 1
    ret

.draw_win:
    call DrawMap
    call DrawItems
    call DrawEnemies
    call DrawMario
    call DrawHUD
    ret

; 6. LEVEL COMPLETE STATE
DoLevelDoneState:
    call DrawLevelDoneScreen
    call WaitEnterToTitle
    ret

; 7. GAME OVER STATE
DoGameOverState:
    call DrawGameOverScreen
    call WaitEnterToTitle
    ret

; 8. EXIT STATE
DoExitState:
    ret

; WaitEnterToTitle
; Purpose: Return to Title state when Enter is newly pressed
WaitEnterToTitle:
    cmp byte [key_table + keyEnter], 1
    je .pressed
    mov byte [enterKeyLatch], 0
    ret
.pressed:
    cmp byte [enterKeyLatch], 1
    je .done
    mov byte [enterKeyLatch], 1
    mov word [gameState], stateTitle
.done:
    ret

; Screen Overlay Drawing Helpers (using FillRect)
DrawTitleScreen:
    ; dark blue border and menu box
    push word 40
    push word 30
    push word 240
    push word 140
    push word 01h
    call FillRect

    ; highlight bar next to selected option (START = y 95, EXIT = y 120)
    mov ax, 95
    cmp byte [menuChoice], 0
    je .draw_cursor
    mov ax, 120
.draw_cursor:
    push word 90
    push ax
    push word 140
    push word 12
    push word 0Eh
    call FillRect

    ; game name, menu options and team details
    push word 116
    push word 50
    push word txt_title
    push word 0Eh
    call hudDrawString

    ; selected option in black on the yellow bar, the other in white
    mov ax, 00h
    mov bx, 0Fh
    cmp byte [menuChoice], 0
    je .draw_options
    mov ax, 0Fh
    mov bx, 00h
.draw_options:
    push word 120
    push word 97
    push word txt_start
    push ax
    call hudDrawString
    push word 144
    push word 122
    push word txt_exit
    push bx
    call hudDrawString

    push word 56
    push word 152
    push word txt_team
    push word 07h
    call hudDrawString
    ret

DrawPauseBox:
    push word 100
    push word 80
    push word 120
    push word 40
    push word 00h
    call FillRect

    push word 136
    push word 96
    push word txt_paused
    push word 0Fh
    call hudDrawString
    ret

DrawLifeLostScreen:
    push word 0
    push word 0
    push word screenWidth
    push word screenHeight
    push word 00h
    call FillRect

    ; world name, Mario icon and lives left
    push word 124
    push word 70
    push word txt_world
    push word 0Fh
    call hudDrawString

    push word 128
    push word 96
    push word mario_small_stand
    push word 16
    push word 16
    push word 0
    call DrawSprite

    push word 152
    push word 100
    push word txt_x
    push word 0Fh
    call hudDrawString
    push word 168
    push word 100
    push word [lives]
    push word 2
    push word 0Fh
    call hudDrawNumber
    ret

DrawLevelDoneScreen:
    push word 40
    push word 30
    push word 240
    push word 140
    push word 02h
    call FillRect

    push word 104
    push word 46
    push word txt_level_done
    push word 0Eh
    call hudDrawString

    ; score, coins and time left
    push word 80
    push word 76
    push word txt_score
    push word 0Fh
    call hudDrawString
    push word 160
    push word 76
    push word [scoreHi]
    push word [scoreLo]
    push word 0Fh
    call hudDrawScore6

    push word 80
    push word 94
    push word txt_coins
    push word 0Fh
    call hudDrawString
    xor ax, ax
    mov al, [coins]
    push word 160
    push word 94
    push ax
    push word 2
    push word 0Fh
    call hudDrawNumber

    push word 80
    push word 112
    push word txt_time
    push word 0Fh
    call hudDrawString
    push word 160
    push word 112
    push word [gameTime]
    push word 3
    push word 0Fh
    call hudDrawNumber

    push word 92
    push word 146
    push word txt_press_enter
    push word 07h
    call hudDrawString
    ret

DrawGameOverScreen:
    push word 40
    push word 40
    push word 240
    push word 120
    push word 04h
    call FillRect

    push word 124
    push word 60
    push word txt_game_over
    push word 0Fh
    call hudDrawString

    ; final score
    push word 80
    push word 92
    push word txt_score
    push word 0Fh
    call hudDrawString
    push word 160
    push word 92
    push word [scoreHi]
    push word [scoreLo]
    push word 0Fh
    call hudDrawScore6

    push word 92
    push word 136
    push word txt_press_enter
    push word 0Eh
    call hudDrawString
    ret

; Screen texts (drawn with hudDrawString from hud.asm)
txt_title           db "SUPER MARIO", 0
txt_start           db "START GAME", 0
txt_exit            db "EXIT", 0
txt_team            db "25F-0105 25F-3032 25F-0119", 0
txt_paused          db "PAUSED", 0
txt_world           db "WORLD 1-1", 0
txt_x               db "x", 0
txt_level_done      db "LEVEL COMPLETE", 0
txt_score           db "SCORE", 0
txt_coins           db "COINS", 0
txt_time            db "TIME", 0
txt_press_enter     db "PRESS ENTER", 0
txt_game_over       db "GAME OVER", 0