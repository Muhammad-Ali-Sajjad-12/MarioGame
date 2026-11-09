; arttest.asm
; Test program for the sprite pictures (Module 4 part B), not part of
; the game.
; Build from the src folder:  nasm -O2 ..\tests\arttest.asm -o arttest.com
;
; It shows every sprite twice on a light blue screen: the top row facing
; right (as drawn) and the bottom row mirrored. Left to right:
;   small Mario (stand, walk, jump), super Mario (stand, walk, jump),
;   Goomba (feet apart, feet together, flat), Koopa (two steps, shell),
;   mushroom, coin.
; Press any key to quit.

%include "const.asm"

org 100h
        jmp start

%include "video.asm"
%include "sprite.asm"

; showSprite x, y, picture, height, flags
%macro showSprite 5
        push word %1
        push word %2
        push word %3
        push word 16
        push word %4
        push word %5
        call DrawSprite
%endmacro

start:
        call InitBuffer
        call InitVideo
        call ClearBuffer

        showSprite 4, 30, mario_small_stand, 16, 0
        showSprite 26, 30, mario_small_walk, 16, 0
        showSprite 48, 30, mario_small_jump, 16, 0
        showSprite 70, 30, mario_super_stand, 32, 0
        showSprite 92, 30, mario_super_walk, 32, 0
        showSprite 114, 30, mario_super_jump, 32, 0
        showSprite 136, 30, goomba_walk1, 16, 0
        showSprite 158, 30, goomba_walk2, 16, 0
        showSprite 180, 30, goomba_flat, 16, 0
        showSprite 202, 30, koopa_walk1, 16, 0
        showSprite 224, 30, koopa_walk2, 16, 0
        showSprite 246, 30, koopa_shell, 16, 0
        showSprite 268, 30, mushroom, 16, 0
        showSprite 290, 30, coin, 16, 0

        showSprite 4, 110, mario_small_stand, 16, spriteMirror
        showSprite 26, 110, mario_small_walk, 16, spriteMirror
        showSprite 48, 110, mario_small_jump, 16, spriteMirror
        showSprite 70, 110, mario_super_stand, 32, spriteMirror
        showSprite 92, 110, mario_super_walk, 32, spriteMirror
        showSprite 114, 110, mario_super_jump, 32, spriteMirror
        showSprite 136, 110, goomba_walk1, 16, spriteMirror
        showSprite 158, 110, goomba_walk2, 16, spriteMirror
        showSprite 180, 110, goomba_flat, 16, spriteMirror
        showSprite 202, 110, koopa_walk1, 16, spriteMirror
        showSprite 224, 110, koopa_walk2, 16, spriteMirror
        showSprite 246, 110, koopa_shell, 16, spriteMirror
        showSprite 268, 110, mushroom, 16, spriteMirror
        showSprite 290, 110, coin, 16, spriteMirror

        call ShowBuffer

        mov ah, 0                   ; wait for a key
        int 16h

        mov ax, 0003h               ; back to text mode
        int 10h
        mov ax, 4C00h               ; end the program
        int 21h
