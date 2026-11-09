; sprtest.asm
; Test program for Module 4 (DrawSprite), not part of the game.
; Build from the src folder:  nasm -O2 ..\tests\sprtest.asm -o sprtest.com
;
; The test sprite is a red letter F with a yellow dot at the top, a blue
; dot in the middle and a white dot at the bottom right. The dots make
; it easy to see which way it faces and which part is cut off.
;
; You should see:
;   - a normal F at the top left and a mirrored F next to it
;   - an F that blinks (it is drawn only every second frame)
;   - F sprites half outside each edge of the screen (left, right, top,
;     bottom, and two corners), showing only the part that is inside
;   - a mirrored F cut off at the left and at the right edge
;   - sprites completely outside the screen are not drawn and must not
;     disturb anything on the screen
; Press any key to quit.

%include "const.asm"

org 100h
        jmp start

%include "video.asm"
%include "sprite.asm"

testSprite:
        db  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
        db  0,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  0,  0
        db  0,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  0,  0
        db  0,  4,  4,  0,  0,  0,  0,  0,  0,  0,  0,  0, 14,  0,  0,  0
        db  0,  4,  4,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
        db  0,  4,  4,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
        db  0,  4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  0,  0,  0,  0,  0
        db  0,  4,  4,  4,  4,  4,  4,  4,  4,  0,  0,  0,  0,  0,  0,  0
        db  0,  4,  4,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  0,  0
        db  0,  4,  4,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
        db  0,  4,  4,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
        db  0,  4,  4,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
        db  0,  4,  4,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
        db  0,  4,  4,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
        db  0,  4,  4,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 15
        db  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0

start:
        call InitBuffer
        call InitVideo

frameLoop:
        call ClearBuffer

        ; Normal and mirrored.
        push word 20
        push word 30
        push word testSprite
        push word 16
        push word 16
        push word 0
        call DrawSprite
        push word 60
        push word 30
        push word testSprite
        push word 16
        push word 16
        push word spriteMirror
        call DrawSprite

        ; Blinking.
        push word 100
        push word 30
        push word testSprite
        push word 16
        push word 16
        push word spriteBlink
        call DrawSprite

        ; Half outside each edge: left, right, top, bottom.
        push word -8
        push word 100
        push word testSprite
        push word 16
        push word 16
        push word 0
        call DrawSprite
        push word 312
        push word 100
        push word testSprite
        push word 16
        push word 16
        push word 0
        call DrawSprite
        push word 150
        push word -8
        push word testSprite
        push word 16
        push word 16
        push word 0
        call DrawSprite
        push word 150
        push word 192
        push word testSprite
        push word 16
        push word 16
        push word 0
        call DrawSprite

        ; Two corners.
        push word -8
        push word -8
        push word testSprite
        push word 16
        push word 16
        push word 0
        call DrawSprite
        push word 312
        push word 192
        push word testSprite
        push word 16
        push word 16
        push word 0
        call DrawSprite

        ; Mirrored and cut off at the left and at the right.
        push word -8
        push word 140
        push word testSprite
        push word 16
        push word 16
        push word spriteMirror
        call DrawSprite
        push word 312
        push word 140
        push word testSprite
        push word 16
        push word 16
        push word spriteMirror
        call DrawSprite

        ; Completely outside: nothing may be drawn or damaged.
        push word -20
        push word 60
        push word testSprite
        push word 16
        push word 16
        push word 0
        call DrawSprite
        push word 330
        push word 60
        push word testSprite
        push word 16
        push word 16
        push word 0
        call DrawSprite
        push word 100
        push word -20
        push word testSprite
        push word 16
        push word 16
        push word 0
        call DrawSprite
        push word 100
        push word 210
        push word testSprite
        push word 16
        push word 16
        push word 0
        call DrawSprite

        call ShowBuffer

        mov ah, 1                   ; is a key waiting?
        int 16h
        jz frameLoop

        mov ah, 0                   ; take the key out of the buffer
        int 16h

        mov ax, 0003h               ; back to text mode
        int 10h
        mov ax, 4C00h               ; end the program
        int 21h
