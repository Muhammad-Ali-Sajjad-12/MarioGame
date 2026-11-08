; Module 10: Collision Detection;
; Tile collision for Mario (manual Section 5.6). He moves one axis at
; a time: first across, then up or down. After each move we look at
; the tiles under his hitbox and push him out of anything solid. His
; speed is never more than 4 pixels per frame, less than one tile, so
; he can never jump through a wall or floor in a single frame.
;
; Mario's hitbox is 12 pixels wide, from x+2 to x+13, and runs from
; y down to y+height-1.


; CheckColumn
; Looks for a solid tile anywhere along a vertical line at x = px,
; from Mario's head to his feet. It tests three points (top, middle
; and bottom), so a 32 pixel tall Super Mario is fully covered.
; Input:  push px, then call
; Output: AX = 1 if any point is solid, 0 if none
; Changes AX only.
CheckColumn:
        push bp
        mov bp, sp
        push bx
        push cx

        mov cx, 0                   ; CX collects the result

        push word [bp+4]
        push word [marioY]          ; top
        call IsSolidAt
        or cx, ax

        mov bx, [marioHeight]
        shr bx, 1
        add bx, [marioY]            ; middle
        push word [bp+4]
        push bx
        call IsSolidAt
        or cx, ax

        mov bx, [marioY]
        add bx, [marioHeight]
        dec bx                      ; bottom row of the hitbox
        push word [bp+4]
        push bx
        call IsSolidAt
        or cx, ax

        mov ax, cx
        pop cx
        pop bx
        pop bp
        ret 2


; CheckRow
; Looks for a solid tile under Mario's left or right edge on the
; horizontal line y = py. Used for his feet and his head.
; Input:  push py, then call
; Output: AX = 1 if solid at (x+2, py) or (x+13, py), 0 if not
; Changes AX only.
CheckRow:
        push bp
        mov bp, sp
        push bx
        push cx

        mov bx, [marioX]
        add bx, hitLeft
        push bx
        push word [bp+4]
        call IsSolidAt
        mov cx, ax

        mov bx, [marioX]
        add bx, hitRight
        push bx
        push word [bp+4]
        call IsSolidAt
        or ax, cx

        pop cx
        pop bx
        pop bp
        ret 2


; MoveX
; Adds the horizontal speed to Mario's position, then pushes him back
; out of any wall he walked into and stops him (Section 5.6, wall in
; front).
; The position is a whole pixel word plus a fraction byte, and the
; speed is 8.8 fixed point. The fraction bytes are added with ADD, and
; the carry goes into the whole pixels with ADC.
; Changes no registers.
MoveX:
        push ax
        push bx

        mov ax, [marioVX]
        add [marioXSub], al         ; fractions, CF = carry into pixels
        mov al, ah
        cbw                         ; AX = whole part of the speed, signed
        adc [marioX], ax            ; whole part plus the carry
                                    ; (MOV and CBW leave CF unchanged)

        cmp word [marioVX], 0
        je mxDone
        jl mxLeft

        ; Moving right: test the right edge of the hitbox.
        mov bx, [marioX]
        add bx, hitRight
        push bx
        call CheckColumn
        cmp ax, 0
        je mxDone
        ; Put his right edge just left of the wall tile:
        ; x + 13 = tileLeft - 1, so x = tileLeft - 14.
        and bx, 0FFF0h              ; left x of the wall tile
        sub bx, hitRight + 1
        jmp mxStop

mxLeft:
        ; Moving left: test the left edge of the hitbox.
        mov bx, [marioX]
        add bx, hitLeft
        push bx
        call CheckColumn
        cmp ax, 0
        je mxDone
        ; Put his left edge just right of the wall tile:
        ; x + 2 = tileLeft + 16, so x = tileLeft + 14.
        sar bx, 4                   ; signed, so it also works left of x = 0
        shl bx, 4                   ; left x of the wall tile
        add bx, tileSize - hitLeft

mxStop:
        mov [marioX], bx
        mov byte [marioXSub], 0
        mov word [marioVX], 0

mxDone:
        pop bx
        pop ax
        ret


; MoveY
; Adds the vertical speed to Mario's position, then:
; when falling or standing, it tests the pixel row just below his
; feet. If that is solid he stands on top of the tile, his vertical
; speed becomes 0 and the stomp chain ends (Section 5.6, feet reach a
; solid tile).
; When rising, it tests his head. If that is solid he is put just
; below the tile and starts to fall (Section 5.6, head hits a block).
; Changes no registers.
MoveY:
        push ax
        push bx

        mov ax, [marioVY]
        add [marioYSub], al
        mov al, ah
        cbw
        adc [marioY], ax

        cmp word [marioVY], 0
        jl myRising

        ; Falling or standing: is there a floor under his feet?
        mov bx, [marioY]
        add bx, [marioHeight]       ; first pixel row below the feet
        push bx
        call CheckRow
        cmp ax, 0
        je myInAir

        and bx, 0FFF0h              ; top of the floor tile
        sub bx, [marioHeight]       ; stand on it
        mov [marioY], bx
        mov byte [marioYSub], 0
        mov word [marioVY], 0
        mov byte [onGround], 1
        mov byte [stompChain], 0    ; landing ends the stomp chain
        jmp myDone

myInAir:
        mov byte [onGround], 0
        jmp myDone

myRising:
        mov byte [onGround], 0
        mov bx, [marioY]            ; row of his head
        push bx
        call CheckRow
        cmp ax, 0
        je myDone

        ; Module 12 will add a call here to make the block react.

        and bx, 0FFF0h
        add bx, tileSize            ; just below the tile
        mov [marioY], bx
        mov byte [marioYSub], 0
        mov word [marioVY], 0

myDone:
        pop bx
        pop ax
        ret


; ClampToLevel
; Keeps Mario between the two ends of the level (x from 0 to 944).
; The left edge of the screen is handled by the camera (Module 6).
; Changes no registers.
ClampToLevel:
        cmp word [marioX], 0
        jge clRightEnd
        mov word [marioX], 0
        jmp clStop
clRightEnd:
        cmp word [marioX], marioMaxX
        jle clDone
        mov word [marioX], marioMaxX
clStop:
        mov byte [marioXSub], 0
        mov word [marioVX], 0
clDone:
        ret


; CheckPitAndFlag
; Pit: once the top of Mario is at or below the bottom of the map
; (y >= 192) he has fallen into a pit, so marioDead becomes deathPit.
; Member 3's code then starts the death sequence.
; Flag: if any corner of his hitbox is on a flag pole tile,
; flagTouched becomes 1 and flagRow holds the row of his feet,
; between 2 and 8, which decides the flag points (Section 5.4).
; Changes no registers.
CheckPitAndFlag:
        push ax
        push bx
        push cx

        cmp word [marioY], mapBottom
        jl cpFlag
        mov byte [marioDead], deathPit
        jmp cpDone

cpFlag:
        mov bx, [marioY]
        add bx, [marioHeight]
        dec bx                      ; BX = y of his feet

        mov cx, [marioX]
        add cx, hitLeft
        push cx
        push word [marioY]
        call GetTile                ; top left
        cmp ax, tileFlag
        je cpTouched
        push cx
        push bx
        call GetTile                ; bottom left
        cmp ax, tileFlag
        je cpTouched

        mov cx, [marioX]
        add cx, hitRight
        push cx
        push word [marioY]
        call GetTile                ; top right
        cmp ax, tileFlag
        je cpTouched
        push cx
        push bx
        call GetTile                ; bottom right
        cmp ax, tileFlag
        jne cpDone

cpTouched:
        mov byte [flagTouched], 1
        shr bx, 4                   ; row of his feet
        cmp bx, 2
        jge cpNotAboveTop
        mov bx, 2                   ; above the pole counts as the top
cpNotAboveTop:
        cmp bx, 8
        jle cpRowOk
        mov bx, 8
cpRowOk:
        mov [flagRow], bl

cpDone:
        pop cx
        pop bx
        pop ax
        ret