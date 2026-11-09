; hudtest.asm
; Test program for Module 13 (HUD and Scoring)
; Build from src folder: nasm -O2 ..\tests\hudtest.asm -o hudtest.com
;
; Tests:
;   - Top 16-row black HUD bar
;   - 6-digit score display (MARIO 000000)
;   - Coin display with icon (x00)
;   - World display (WORLD 1-1)
;   - Time display (TIME 300)
;   - Health display (2 hearts, toggled with 'H')
;   - Lives display (x 3)
;
; Controls:
;   Space  - Add +100 points
;   C      - Add 1 coin (at 100 coins, resets to 0 and adds +1 life)
;   H      - Toggle Mario HP (1 heart <-> 2 hearts)
;   Esc    - Quit to DOS

%include "const.asm"

org 100h
        jmp start

; Test stubs for external variables from other members
marioHp         db 2                ; 2 = Super (2 filled hearts), 1 = Small (1 heart)
gameTime        dw 300              ; countdown clock
lastTick        dw 0

start:
        call InitBuffer             ; initialize 64KB frame buffer
        call InstallInterrupts      ; 30 Hz timer and keyboard ISR
        call InitVideo              ; VGA mode 13h and custom palette

        ; Initial test values
        push word 1250
        call AddScore

        call AddCoin
        call AddCoin
        call AddCoin

testLoop:
        call WaitTick

        ; Check Esc key (scan code 01h)
        cmp byte [key_table + 01h], 0
        jne quit

        ; Space key (scan code 39h) adds +100 points
        cmp byte [key_table + 39h], 1
        jne .checkC
        push word 100
        call AddScore
        mov byte [key_table + 39h], 0   ; consume key press

.checkC:
        ; 'C' key (scan code 2Eh) adds 1 coin
        cmp byte [key_table + 2Eh], 1
        jne .checkH
        call AddCoin
        mov byte [key_table + 2Eh], 0

.checkH:
        ; 'H' key (scan code 23h) toggles HP
        cmp byte [key_table + 23h], 1
        jne .render
        xor byte [marioHp], 3           ; toggles 1 <-> 2
        mov byte [key_table + 23h], 0

.render:
        call ClearBuffer
        call DrawHUD
        call ShowBuffer

        jmp testLoop

quit:
        call RestoreInterrupts
        mov ax, 0003h
        int 10h
        mov ax, 4C00h
        int 21h


; WaitTick
; Synchronizes loop with 30 Hz timer
WaitTick:
        push ax
.wtLoop:
        mov ax, [tick_counter]
        cmp ax, [lastTick]
        je .wtLoop
        mov [lastTick], ax
        pop ax
        ret

; Include dependencies
%include "video.asm"
%include "hud.asm"
%include "intr.asm"
