; buftest.asm
; Test program for Module 5, not part of the game.
; Build from the src folder:  nasm -O2 ..\tests\buftest.asm -o buftest.com
;
; Every frame is drawn into the frame buffer first and then copied to
; the screen. You should see a light blue sky, a green and brown ground
; and a red box that moves left and right and turns at the screen edges,
; smoothly and without flicker. Press any key to quit.

%include "const.asm"

org 100h
        jmp start

%include "video.asm"

boxX            dw 0                ; x of the red box
boxStep         dw 2                ; pixels per frame, negative = left

start:
        call InitBuffer             ; second segment from DOS
        call InitVideo

frameLoop:
        call ClearBuffer            ; empty sky

        ; Ground: a green strip on top of a brown one.
        push word 0
        push word 176
        push word screenWidth
        push word 4
        push word colourGreen
        call FillRect
        push word 0
        push word 180
        push word screenWidth
        push word 20
        push word colourBrown
        call FillRect

        ; The moving red box.
        push word [boxX]
        push word 100
        push word 24
        push word 24
        push word colourRed
        call FillRect

        call ShowBuffer             ; copy the buffer to the screen

        ; Move the box and turn around at the edges.
        mov ax, [boxX]
        add ax, [boxStep]
        mov [boxX], ax
        cmp ax, 0
        jg notAtLeft
        neg word [boxStep]
        jmp checkKey
notAtLeft:
        cmp ax, screenWidth - 24
        jl checkKey
        neg word [boxStep]

checkKey:
        mov ah, 1                   ; is a key waiting?
        int 16h
        jz frameLoop                ; no, draw the next frame

        mov ah, 0                   ; take the key out of the buffer
        int 16h

        mov ax, 0003h               ; back to text mode
        int 10h
        mov ax, 4C00h               ; end the program
        int 21h
