; sprite.asm
; Module 4: Sprites (Member 1)
;
; A sprite is a small picture stored as one byte per pixel, row after
; row. A pixel with colour 0 is transparent and is skipped, so the
; background shows through around Mario's shape.
;
; Procedures here:
;   DrawSprite   draws a sprite, mirrored if asked, cut to the screen

; Flags for DrawSprite (they can be added together)
spriteMirror    equ 1               ; draw the sprite facing the other way
spriteBlink     equ 2               ; draw it only every second frame

; Working variables of DrawSprite
drwSkipX        dw 0                ; columns cut off at the left edge
drwSkipY        dw 0                ; rows cut off at the top edge
drwStartX       dw 0                ; screen column of the first visible pixel
drwStartY       dw 0                ; screen row of the first visible pixel
drwCols         dw 0                ; visible columns
drwRows         dw 0                ; visible rows
drwColFirst     dw 0                ; first column to read in each sprite row
drwRowSrc       dw 0                ; address of the start of the current row


; DrawSprite
; Purpose: Draw a sprite into the frame buffer. Parts outside the screen
; are cut off, so x and y can be negative or beyond the screen edges.
; Inputs:  push x          (signed, screen position of the left edge)
;          push y          (signed, screen position of the top edge)
;          push pointer    (address of the first pixel of the sprite)
;          push width
;          push height
;          push flags      (spriteMirror and/or spriteBlink, or 0)
;          then call
; Outputs: None   Registers changed: None
DrawSprite:
        push bp
        mov bp, sp
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        push es

        ; Blinking: with spriteBlink the sprite is left out on every
        ; second frame (frameCount is increased by ShowBuffer).
        test word [bp+4], spriteBlink
        jz drawShow
        test word [frameCount], 1
        jz drawShow                 ; even frame: draw it
        jmp drawDone                ; odd frame: leave it out
drawShow:

        ; Rows. AX = y, BX = rows still to draw.
        mov ax, [bp+12]
        mov bx, [bp+6]
        mov word [drwSkipY], 0
        cmp ax, 0
        jge drawTopOk
        neg ax                      ; AX = how many rows are above the screen
        mov [drwSkipY], ax
        sub bx, ax                  ; they are not drawn
        xor ax, ax                  ; the first visible row is screen row 0
drawTopOk:
        mov [drwStartY], ax
        add ax, bx                  ; screen row after the last one
        cmp ax, screenHeight
        jle drawBottomOk
        sub ax, screenHeight        ; AX = how many rows are below the screen
        sub bx, ax
drawBottomOk:
        cmp bx, 0
        jg drawRowsVisible
        jmp drawDone                ; nothing of it is on the screen
drawRowsVisible:
        mov [drwRows], bx

        ; Columns, the same way with x and the width.
        mov ax, [bp+14]
        mov bx, [bp+8]
        mov word [drwSkipX], 0
        cmp ax, 0
        jge drawLeftOk
        neg ax
        mov [drwSkipX], ax
        sub bx, ax
        xor ax, ax
drawLeftOk:
        mov [drwStartX], ax
        add ax, bx
        cmp ax, screenWidth
        jle drawRightOk
        sub ax, screenWidth
        sub bx, ax
drawRightOk:
        cmp bx, 0
        jg drawColsVisible
        jmp drawDone
drawColsVisible:
        mov [drwCols], bx

        ; DI = where the first visible pixel goes: row * 320 + column
        mov ax, [drwStartY]
        mov di, ax
        shl ax, 8
        shl di, 6
        add di, ax
        add di, [drwStartX]
        mov es, [bufferSeg]

        ; Address of the first visible row of the sprite.
        mov ax, [drwSkipY]
        mul word [bp+8]             ; skipped rows * width
        add ax, [bp+10]             ; + start of the sprite
        mov [drwRowSrc], ax

        ; Which column is read first, and in which direction (BX).
        ; Facing right we read from the left, mirrored from the right.
        mov bx, 1
        mov ax, [drwSkipX]
        test word [bp+4], spriteMirror
        jz drawNotMirrored
        mov bx, -1
        mov ax, [bp+8]
        dec ax                      ; last column
        sub ax, [drwSkipX]
drawNotMirrored:
        mov [drwColFirst], ax

        mov dx, [drwRows]
drawRow:
        mov si, [drwRowSrc]
        add si, [drwColFirst]
        push di                     ; remember the start of this screen row
        mov cx, [drwCols]
drawPixel:
        mov al, [si]
        add si, bx                  ; next pixel to the right or to the left
        cmp al, 0
        je drawSkip                 ; colour 0 is transparent
        mov [es:di], al
drawSkip:
        inc di
        loop drawPixel
        pop di
        add di, screenWidth         ; next screen row
        mov ax, [bp+8]
        add [drwRowSrc], ax         ; next sprite row
        dec dx
        jnz drawRow

drawDone:
        pop es
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        pop bp
        ret 12
