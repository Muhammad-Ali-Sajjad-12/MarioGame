; mario.asm
; Super Mario Engine - Module 1: Program Skeleton (Member 1)
;
; A DOS .COM program for NASM 0.98.38 and DOSBox.
; It sets up the frame buffer, the keyboard and 30 Hz timer handlers
; (intr.asm) and VGA mode 13h (320 x 200, 256 colours). Then every frame
; it clears the frame buffer, lets the current game state update and draw
; itself (game.asm), shows the picture and counts down the sound. When the
; state becomes EXIT it puts everything back and returns to DOS.
;
; Build: build.bat          Run: mario

%include "const.asm"            ; only EQU lines, so it adds no bytes

org 100h                        ; a .COM program is loaded at offset 100h
        jmp start               ; jump over the data below

; Variables of the main program
lastTick        dw 0            ; tick_counter value of the previous frame

start:
        call InitBuffer         ; frame buffer first (video.asm)
        call InstallInterrupts  ; keyboard handler and 30 Hz timer

        call InitVideo          ; mode 13h, palette (video.asm)

        mov word [gameState], stateTitle

gameLoop:
        call WaitTick           ; one pass of this loop = one frame
        call ClearBuffer        ; start the new picture with an empty sky

        call UpdateGameState    ; Modules 14 and 15: update and draw the current state

        call ShowBuffer         ; show the finished picture
        call UpdateSound        ; stop the sound effect when its time is up

        cmp word [gameState], stateExit
        jne gameLoop

quit:
        call SoundMute          ; make sure the speaker is silent
        call RestoreInterrupts  ; old keyboard and timer back, 18.2 Hz

        mov ax, 0003h           ; back to 80 x 25 text mode
        int 10h
        mov ax, 4C00h           ; DOS function 4Ch: end the program
        int 21h


; WaitTick
; Waits until the timer handler has increased tick_counter. The timer
; runs at 30 ticks per second, so the game runs at 30 frames per second
; on every computer.
; Inputs: None   Outputs: None   Registers changed: None
WaitTick:
        push ax
wtLoop:
        mov ax, [tick_counter]
        cmp ax, [lastTick]
        je wtLoop               ; same value as before, keep waiting
        mov [lastTick], ax
        pop ax
        ret


; Other files are included at the end, after the code.
%include "video.asm"            ; Modules 2 and 5 (Member 1)
%include "sprite.asm"           ; Module 4 (Member 1)
%include "hud.asm"              ; Module 13 (Member 1)
%include "intr.asm"             ; Modules 7 and 8 (Member 3)
%include "sound.asm"            ; Bonus sound effects (Member 3)
%include "map.asm"              ; Module 3 (Member 2)
%include "hero.asm"             ; Module 9 (Member 2)
%include "collide.asm"          ; Module 10 (Member 2)
%include "camera.asm"           ; Module 6 (Member 2)
%include "items.asm"            ; Module 12 (Member 2)
%include "enemies.asm"          ; Module 11 (Member 3)
%include "game.asm"             ; Modules 14 and 15 (Member 3)