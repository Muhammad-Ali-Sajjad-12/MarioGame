; Test program for Module 3, not part of the game. It shows the level
; and scrolls it with the arrow keys (Right and Left, 8 pixels at a
; time). Esc quits.
; It uses its own simple FillRect that draws straight to video memory
; and keyboard input. The game itself will use Member 1's
; FillRect and Member 3's keyboard handler.

%include "const.asm"

org 100h
        jmp start

cameraX     dw 0                    ; the real one comes with Module 6

start:
        mov ax, 0013h               ; VGA mode 13h, 320 x 200
        int 10h
        call ResetMap

drawFrame:
        ; Clear the screen to sky colour (9 is light blue).
        push es
        mov ax, 0A000h
        mov es, ax
        mov di, 0
        mov al, 9
        mov cx, 64000
        cld
        rep stosb
        pop es

        call DrawMap

        ; Wait for a key. AH returns the scan code.
        mov ah, 0
        int 16h
        cmp ah, 01h                 ; Esc
        je quit
        cmp ah, 4Dh                 ; Right arrow
        je scrollRight
        cmp ah, 4Bh                 ; Left arrow
        je scrollLeft
        jmp drawFrame

scrollRight:
        add word [cameraX], 8
        cmp word [cameraX], levelWidth - screenWidth
        jle drawFrame
        mov word [cameraX], levelWidth - screenWidth   ; stop at 640
        jmp drawFrame

scrollLeft:
        sub word [cameraX], 8
        jge drawFrame
        mov word [cameraX], 0
        jmp drawFrame

quit:
        mov ax, 0003h               ; back to text mode
        int 10h
        mov ax, 4C00h
        int 21h


; FillRect (test version)
; Fills a rectangle directly in video memory. The pixel at (x, y) is
; at offset y*320 + x, and y*320 is worked out as y*256 + y*64.
; Input:  push x, push y, push width, push height, push colour, then call
; Changes no registers.
FillRect:
        push bp
        mov bp, sp
        push ax
        push bx
        push cx
        push dx
        push di
        push es

        mov ax, 0A000h
        mov es, ax
        mov ax, [bp+10]             ; y
        mov bx, ax
        shl ax, 8
        shl bx, 6
        add ax, bx                  ; y * 320
        add ax, [bp+12]             ; + x
        mov di, ax
        mov al, [bp+4]              ; colour
        mov dx, [bp+6]              ; rows to fill
frRow:
        push di
        mov cx, [bp+8]              ; width
        rep stosb
        pop di
        add di, screenWidth         ; next row
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