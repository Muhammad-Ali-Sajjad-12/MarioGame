; vidtest.asm
; Test program for Module 2, not part of the game.
; Build from the src folder:  nasm -O2 ..\tests\vidtest.asm -o vidtest.com
;
; You should see: a light blue screen, a row of 16 colour squares (the
; default colours 0 to 15; number 9 has the colour of the background so
; it seems missing), three squares below them in our own colours (skin,
; dark brown, cream), a yellow diagonal line, and a white dot in each
; corner of the screen. Pixels placed outside the screen must not draw
; or crash anything. Press any key to quit.

%include "const.asm"

org 100h
        jmp start

%include "video.asm"

start:
        call InitVideo

        ; Light blue background over the whole screen.
        push word 0
        push word 0
        push word screenWidth
        push word screenHeight
        push word colourSky
        call FillRect

        ; 16 squares, one for each default colour, 20 pixels apart.
        mov cx, 0
swatchLoop:
        mov ax, cx
        mov bx, 20
        mul bx                      ; AX = colour * 20
        push ax                     ; x
        push word 20                ; y
        push word 16                ; width
        push word 16                ; height
        push cx                     ; colour
        call FillRect
        inc cx
        cmp cx, 16
        jb swatchLoop

        ; Our own three colours.
        push word 0
        push word 50
        push word 16
        push word 16
        push word colourSkin
        call FillRect

        push word 20
        push word 50
        push word 16
        push word 16
        push word colourDarkBrown
        call FillRect

        push word 40
        push word 50
        push word 16
        push word 16
        push word colourCream
        call FillRect

        ; Diagonal line of single pixels, x = y from 100 to 179.
        mov cx, 0
lineLoop:
        mov ax, cx
        add ax, 100
        push ax                     ; x
        push ax                     ; y
        push word colourYellow
        call PutPixel
        inc cx
        cmp cx, 80
        jb lineLoop

        ; A white dot in each corner.
        push word 0
        push word 0
        push word colourWhite
        call PutPixel
        push word 319
        push word 0
        push word colourWhite
        call PutPixel
        push word 0
        push word 199
        push word colourWhite
        call PutPixel
        push word 319
        push word 199
        push word colourWhite
        call PutPixel

        ; Outside the screen: all of these must be ignored.
        push word 320
        push word 10
        push word colourWhite
        call PutPixel
        push word 10
        push word 200
        push word colourWhite
        call PutPixel
        push word 0FFFFh            ; -1 as a signed number
        push word 5
        push word colourWhite
        call PutPixel
        push word 5
        push word 0FFFFh
        push word colourWhite
        call PutPixel

        mov ah, 0                   ; wait for a key
        int 16h

        mov ax, 0003h               ; back to text mode
        int 10h
        mov ax, 4C00h               ; end the program
        int 21h
