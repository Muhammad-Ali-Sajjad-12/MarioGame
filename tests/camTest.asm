; camtest.asm
; Test program for Module 6, not part of the game. It runs Mario through
; the level with the real camera, the real sprites and the team's frame
; buffer, keyboard and timer code. Left and Right walk, Left Shift runs,
; Space jumps, Esc quits. A pit or the flag pole restarts the level.
; Press I to make Mario blink for two seconds and S to switch between
; Small and Super Mario.

%include "const.asm"

org 100h
        jmp start

lastTick        dw 0
sKeyLatch       db 0

start:
        call InitBuffer             ; frame buffer (video.asm)
        call InstallInterrupts      ; keyboard and 30 Hz timer (intr.asm)
        call InitVideo              ; mode 13h and palette (video.asm)

restartLevel:
        call ResetMap
        call ResetHero
        mov word [cameraX], 0

gameLoop:
        call WaitTick
        cmp byte [key_table + 01h], 0   ; Esc
        jne quit

        ; I key (17h): two seconds of blinking
        cmp byte [key_table + 17h], 0
        je checkFormKey
        mov byte [invulnTimer], 60
checkFormKey:
        ; S key (1Fh): switch Small and Super, once per key press
        cmp byte [key_table + 1Fh], 0
        jne sHeld
        mov byte [sKeyLatch], 0
        jmp updateAll
sHeld:
        cmp byte [sKeyLatch], 0
        jne updateAll
        mov byte [sKeyLatch], 1
        mov ax, formSuper
        cmp byte [marioForm], formSuper
        jne setForm
        mov ax, formSmall
setForm:
        push ax
        call SetForm

updateAll:
        call UpdateMario
        call UpdateCamera
        cmp byte [invulnTimer], 0
        je checkEnd
        dec byte [invulnTimer]
checkEnd:
        cmp byte [marioDead], deathNone
        jne restartLevel
        cmp byte [flagTouched], 0
        jne restartLevel

        call ClearBuffer
        call DrawMap
        call DrawMario
        call ShowBuffer
        jmp gameLoop

quit:
        call RestoreInterrupts
        mov ax, 0003h
        int 10h
        mov ax, 4C00h
        int 21h


; WaitTick
; Waits until the timer handler increases tick_counter (30 per second).
WaitTick:
        push ax
wtLoop:
        mov ax, [tick_counter]
        cmp ax, [lastTick]
        je wtLoop
        mov [lastTick], ax
        pop ax
        ret

%include "video.asm"
%include "sprite.asm"
%include "intr.asm"
%include "map.asm"
%include "hero.asm"
%include "collide.asm"
%include "camera.asm"