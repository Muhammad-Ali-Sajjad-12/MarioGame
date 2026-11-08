; heroTest.asm
; Test program for Modules 9 and 10, not part of the game. Mario is a
; red box you can control: Left and Right to walk, Left Shift to run,
; Space to jump (hold it for a higher jump). Falling into a pit or
; touching the flag pole puts him back at the start. Esc quits.
;
; It uses Member 3's keyboard and timer handlers from intr.asm, and its
; own simple versions of things other members are still building:
; a frame buffer in the next 64 KB segment (Member 1, Module 5),
; FillRect drawing into that buffer (Member 1, Module 2),
; and a simple camera (Module 6, coming later).

%include "const.asm"

org 100h
        jmp start

bufferSeg       dw 0                ; segment of the frame buffer
lastTick        dw 0
cameraX         dw 0

start:
        ; The frame buffer goes in the 64 KB right after our program.
        mov ax, cs
        add ax, 1000h
        mov [bufferSeg], ax

        ; Member 3's keyboard handler and 30 Hz timer (intr.asm).
        call InstallInterrupts

        mov ax, 0013h               ; VGA mode 13h, 320 x 200
        int 10h

        call ResetMap
        call ResetHero
        mov word [cameraX], 0

gameLoop:
        call WaitTick

        cmp byte [key_table + 01h], 0   ; Esc
        jne quit

        call UpdateMario
        call TestCamera

        ; Pit or flag: back to the start.
        cmp byte [marioDead], deathNone
        jne restartLevel
        cmp byte [flagTouched], 0
        jne restartLevel
        jmp drawFrame

restartLevel:
        call ResetMap
        call ResetHero
        mov word [cameraX], 0

drawFrame:
        call ClearBuffer
        call DrawMap

        ; Mario as a red box at his screen position.
        mov ax, [marioX]
        sub ax, [cameraX]
        push ax
        push word [marioY]
        push word 16
        push word [marioHeight]
        push word 4                 ; red
        call ClippedFill

        call ShowBuffer
        jmp gameLoop

quit:
        ; Keyboard, timer handler and timer rate back to normal.
        call RestoreInterrupts

        mov ax, 0003h               ; text mode
        int 10h
        mov ax, 4C00h
        int 21h


; WaitTick
; Waits until Member 3's tick_counter changes. The timer runs at
; 30 ticks per second, so this gives 30 frames per second.
WaitTick:
        push ax
wtLoop:
        mov ax, [tick_counter]
        cmp ax, [lastTick]
        je wtLoop
        mov [lastTick], ax
        pop ax
        ret

; TestCamera (simple version of Module 6)
; The camera follows Mario once he passes the middle of the screen,
; never scrolls back, stops at the end of the level, and Mario cannot
; walk off the left edge of the screen.
TestCamera:
        push ax
        mov ax, [marioX]
        sub ax, 160
        cmp ax, [cameraX]
        jle tcLeftWall
        cmp ax, levelWidth - screenWidth
        jle tcSet
        mov ax, levelWidth - screenWidth
tcSet:
        mov [cameraX], ax
tcLeftWall:
        mov ax, [marioX]
        cmp ax, [cameraX]
        jge tcDone
        mov ax, [cameraX]
        mov [marioX], ax
        mov word [marioVX], 0
tcDone:
        pop ax
        ret


; ClearBuffer
; Fills the frame buffer with sky colour using REP STOSW, two pixels
; at a time.
ClearBuffer:
        push ax
        push cx
        push di
        push es
        mov es, [bufferSeg]
        mov di, 0
        mov ax, 0909h               ; two light blue pixels
        mov cx, 32000
        cld
        rep stosw
        pop es
        pop di
        pop cx
        pop ax
        ret


; ShowBuffer
; Waits for the start of the screen's vertical retrace, then copies
; the whole frame buffer to video memory with REP MOVSW. Copying
; during the retrace avoids tearing.
ShowBuffer:
        push ax
        push cx
        push dx
        push si
        push di
        push ds
        push es

        mov dx, 03DAh
sbWaitEnd:
        in al, dx
        test al, 8
        jnz sbWaitEnd               ; wait until a retrace is not running
sbWaitStart:
        in al, dx
        test al, 8
        jz sbWaitStart              ; then wait for the next one to start

        mov ax, 0A000h
        mov es, ax
        mov ds, [cs:bufferSeg]
        mov si, 0
        mov di, 0
        mov cx, 32000
        cld
        rep movsw

        pop es
        pop ds
        pop di
        pop si
        pop dx
        pop cx
        pop ax
        ret


; FillRect (test version of Module 2)
; Fills a rectangle in the frame buffer. Pixel (x, y) is at offset
; y*320 + x, worked out as y*256 + y*64 + x.
; Input:  push x, push y, push width, push height, push colour, then call
FillRect:
        push bp
        mov bp, sp
        push ax
        push bx
        push cx
        push dx
        push di
        push es

        mov es, [bufferSeg]
        mov ax, [bp+10]
        mov bx, ax
        shl ax, 8
        shl bx, 6
        add ax, bx
        add ax, [bp+12]
        mov di, ax
        mov al, [bp+4]
        mov dx, [bp+6]
frRow:
        push di
        mov cx, [bp+8]
        rep stosb
        pop di
        add di, screenWidth
        dec dx
        jnz frRow

        pop es
        pop di
        pop dx
        pop cx
        pop bx
        pop ax
        pop bp
        ret 10

%include "map.asm"
%include "hero.asm"
%include "collide.asm"
%include "intr.asm"