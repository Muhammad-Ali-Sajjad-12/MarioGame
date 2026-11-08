; mario.asm
; Super Mario Engine - Module 1: Program Skeleton (Member 1)
;
; A DOS .COM program for NASM 0.98.38 and DOSBox.
; So far it does only the basics: installs the keyboard and 30 Hz timer
; handlers (intr.asm), switches to VGA mode 13h (320 x 200, 256 colours),
; waits for Esc, then puts everything back and returns to DOS.
; Later modules add their %include lines and calls at the marked places.
;
; Build: build.bat          Run: mario

%include "const.asm"            ; only EQU lines, so it adds no bytes

org 100h                        ; a .COM program is loaded at offset 100h
        jmp start               ; jump over the data below

; Variables of the main program
lastTick        dw 0            ; tick_counter value of the previous frame

start:
        call InstallInterrupts  ; keyboard handler and 30 Hz timer

        mov ax, 0013h           ; AH = 0 (set video mode), AL = 13h
        int 10h

gameLoop:
        call WaitTick           ; one pass of this loop = one frame

        ; The update and draw calls of the other modules go here.

        cmp byte [key_table + 01h], 0   ; scan code 01h is the Esc key
        je gameLoop

quit:
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
%include "intr.asm"             ; Modules 7 and 8 (Member 3)
