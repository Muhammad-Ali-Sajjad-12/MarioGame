; itemtest.asm
; Test program for Module 12, not part of the game. Play the level with
; the real HUD so you can see the score and coins change. Left and
; Right walk, Left Shift runs, Space jumps, S switches between Small
; and Super Mario, Esc quits. A pit or the flag pole restarts the level.

%include "const.asm"

org 100h
        jmp start

lastTick        dw 0
sKeyLatch       db 0
gameTime        dw 300              ; shown on the HUD (game.asm has the real one)

start:
        call InitBuffer
        call InstallInterrupts
        call InitVideo

restartLevel:
        call ResetMap
        call ResetHero
        call ResetItems
        mov word [cameraX], 0

gameLoop:
        call WaitTick
        cmp byte [key_table + 01h], 0   ; Esc
        jne quit

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
        call UpdateItems
        call UpdateCamera

        ; Keep the beeps short: switch the speaker off every 4 frames.
        test word [frameCount], 3
        jnz checkEnd
        call SoundMute

checkEnd:
        cmp byte [marioDead], deathNone
        jne restartLevel
        cmp byte [flagTouched], 0
        jne restartLevel

        call ClearBuffer
        call DrawMap
        call DrawItems
        call DrawMario
        call DrawHUD
        call ShowBuffer
        jmp gameLoop

quit:
        call SoundMute
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
%include "hud.asm"
%include "sound.asm"
%include "intr.asm"
%include "map.asm"
%include "hero.asm"
%include "collide.asm"
%include "camera.asm"
%include "items.asm"