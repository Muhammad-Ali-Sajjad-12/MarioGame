; Module 3: Level Map and Tile Drawing
; The level is 60 columns by 12 rows of tiles. Each tile is one byte
; holding its tile code stored row after row so the tile at
; (col, row) is at originalMap + row*60 + col.
;
; originalMap is never changed. workingMap is the copy used while
; playing bricks break and coins disappear there. ResetMap copies
; the original over it at the start of every life.
;
; Level contents (manual Section 5.15):
; pits at columns 26-27 and 42-44, pipes at 22-23 (2 high) and
; 31-32 (3 high), coin blocks at 17, 38, 46 and mushroom blocks
; at 9, 48 (all on row 6), bricks at 13-15 and 35-37, ten free coins,
; stairs at 50-53 and the flag pole at column 56 (rows 2-8).

originalMap:
        db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0   ; row  0
        db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0   ; 
        db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,12, 0, 0, 0   ;  
        db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,12, 0, 0, 0   ;   
        db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,12, 0, 0, 0   ;   
        db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,11,11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,12, 0, 0, 0   ;   
        db  0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 2, 2, 2, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 3, 0, 0, 0, 0, 0, 0, 0, 3, 0, 4, 0, 0, 0, 0,10, 0, 0,12, 0, 0, 0   ;   
        db  0, 0, 0, 0, 0,11,11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,11, 0, 0, 0, 0, 0,11,11, 0, 0, 0, 6, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0,11,11,11, 0, 0, 0, 0, 0, 0, 0,10,10, 0, 0,12, 0, 0, 0   ;   
        db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 7, 0, 0, 0, 0, 0, 0, 0, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,10,10,10, 0, 0,12, 0, 0, 0   ;   
        db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 9, 0, 0, 0, 0, 0, 0, 0, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,10,10,10,10, 0, 0,10, 0, 0, 0   ;   
        db  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1   ;  
        db  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1   ; row 11

; Working copy of the map. Its starting values do not matter because
; ResetMap fills it before it is used.
workingMap:
        times mapSize db 0

; Offset of the start of each row (row * 60). Looking it up here is
; simpler and faster than multiplying.
rowOffset:
        dw 0, 60, 120, 180, 240, 300, 360, 420, 480, 540, 600, 660

; Placeholder colours for each tile code, from the default VGA palette.
; A tile is drawn in its edge colour with the fill colour 1 pixel
; inside so neighbouring tiles look separate. Member 1 can change them.
tileEdge:  db 0, 0, 4, 6, 6, 0, 2, 2, 2, 2, 8, 14, 2
tileFill:  db 0, 6, 12, 14, 14, 6, 10, 10, 10, 10, 7, 14, 2


; TileIndex: Converts a pixel position in the level to the offset of its tile
; in the map.
; Input:  push px, push py, then call
; Output: AX = offset (0 to 719) with CF = 0,
;         or CF = 1 if the point is outside the map
; Changes AX only.
TileIndex:
        push bp
        mov bp, sp
        push bx

        mov ax, [bp+6]              ; px
        mov bx, [bp+4]              ; py

        ; Signed compares, because positions can be negative.
        cmp ax, 0
        jl tiOutside
        cmp ax, levelWidth
        jge tiOutside
        cmp bx, 0
        jl tiOutside
        cmp bx, mapBottom
        jge tiOutside

        ; A tile is 16 pixels, so shifting right by 4 gives the tile.
        shr ax, 4                   ; column
        shr bx, 4                   ; row
        shl bx, 1                   ; rowOffset holds words
        add ax, [rowOffset + bx]   ; row*60 + column
        clc
        jmp tiDone

tiOutside:
        stc

tiDone:
        pop bx
        pop bp
        ret 4


; GetTile
; Returns the tile code at a pixel position. All collision and block
; logic uses this procedure, and it always reads the working map.
; Left or right of the level counts as ground, so the level ends act
; as walls. Above or below the map counts as sky, so Mario can fall
; into a pit and jump above the top row.
; Input:  push px, push py, then call
; Output: AX = tile code
; Changes AX only.
GetTile:
        push bp
        mov bp, sp
        push bx

        push word [bp+6]
        push word [bp+4]
        call TileIndex
        jc gtOutside

        mov bx, ax
        mov al, [workingMap + bx]
        mov ah, 0
        jmp gtDone

gtOutside:
        mov ax, tileSky
        cmp word [bp+6], 0
        jl gtWall
        cmp word [bp+6], levelWidth
        jl gtDone                   ; inside the level width, so sky
gtWall:
        mov ax, tileGround

gtDone:
        pop bx
        pop bp
        ret 4


; IsSolidAt
; Tells whether the tile at a pixel position is solid (codes 1 to 10).
; Input:  push px, push py, then call
; Output: AX = 1 if solid, 0 if not
; Changes AX only.
IsSolidAt:
        push bp
        mov bp, sp

        push word [bp+6]
        push word [bp+4]
        call GetTile

        cmp ax, tileGround
        jb isNotSolid               ; sky
        cmp ax, tileStair
        ja isNotSolid               ; coin or flag pole
        mov ax, 1
        jmp isDone
isNotSolid:
        mov ax, 0
isDone:
        pop bp
        ret 4


; SetTile
; Changes one tile of the working map, for example when a brick
; breaks or a coin is collected. Points outside the map are ignored.
; Input:  push px, push py, push new tile code, then call
; Changes no registers.
SetTile:
        push bp
        mov bp, sp
        push ax
        push bx

        push word [bp+8]
        push word [bp+6]
        call TileIndex
        jc stDone

        mov bx, ax
        mov al, [bp+4]
        mov [workingMap + bx], al

stDone:
        pop bx
        pop ax
        pop bp
        ret 6


; ResetMap
; Copies the original map over the working map, so every brick,
; ? block and coin comes back. Used for every new life and new game.
; REP MOVSB copies CX bytes from DS:SI to ES:DI. Both maps are in our
; own segment, so ES is set equal to DS first.
; Changes no registers.
ResetMap:
        push cx
        push si
        push di
        push es

        push ds
        pop es
        mov si, originalMap
        mov di, workingMap
        mov cx, mapSize
        cld                         ; copy forwards
        rep movsb

        pop es
        pop di
        pop si
        pop cx
        ret


; ClippedFill
; Calls FillRect from Member 1 after cutting the rectangle to fit the
; 320 x 200 screen. This matters because the left-most tile column can
; start at x = -15, and drawing outside the screen would write past
; the end of the frame buffer.
; Input:  push x, push y, push width, push height, push colour, then call
; Changes no registers.
ClippedFill:
        push bp
        mov bp, sp
        push ax
        push bx
        push cx
        push dx

        mov ax, [bp+12]             ; x
        mov bx, [bp+10]             ; y
        mov cx, [bp+8]              ; width
        mov dx, [bp+6]              ; height

        ; Left edge: if x is negative, drop the hidden part.
        cmp ax, 0
        jge cfLeftOk
        add cx, ax
        mov ax, 0
cfLeftOk:
        ; Top edge, same idea.
        cmp bx, 0
        jge cfTopOk
        add dx, bx
        mov bx, 0
cfTopOk:
        ; Right edge: if x + width > 320, width = 320 - x.
        push ax
        add ax, cx
        cmp ax, screenWidth
        pop ax
        jle cfRightOk
        mov cx, screenWidth
        sub cx, ax
cfRightOk:
        ; Bottom edge: if y + height > 200, height = 200 - y.
        push bx
        add bx, dx
        cmp bx, screenHeight
        pop bx
        jle cfBottomOk
        mov dx, screenHeight
        sub dx, bx
cfBottomOk:
        ; Nothing left to draw if the rectangle is fully off screen.
        cmp cx, 0
        jle cfDone
        cmp dx, 0
        jle cfDone

        push ax
        push bx
        push cx
        push dx
        push word [bp+4]
        call FillRect

cfDone:
        pop dx
        pop cx
        pop bx
        pop ax
        pop bp
        ret 10


; DrawTile
; Draws one tile at a screen position as a coloured square. Sky is
; skipped because the frame buffer is already cleared to sky colour.
; Coins and the flag pole get their own small shapes.
; Input:  push screen x, push screen y, push tile code, then call
; Changes no registers.
DrawTile:
        push bp
        mov bp, sp
        push ax
        push bx

        mov bx, [bp+4]              ; tile code, also the table index
        cmp bx, tileSky
        je dtDone
        cmp bx, tileCoin
        je dtCoin
        cmp bx, tileFlag
        je dtFlag

        ; Solid block: the whole tile in the edge colour,
        push word [bp+8]
        push word [bp+6]
        push word 16
        push word 16
        mov al, [tileEdge + bx]
        mov ah, 0
        push ax
        call ClippedFill

        ; then a 14 x 14 square in the fill colour inside it.
        mov ax, [bp+8]
        inc ax
        push ax
        mov ax, [bp+6]
        inc ax
        push ax
        push word 14
        push word 14
        mov al, [tileFill + bx]
        mov ah, 0
        push ax
        call ClippedFill
        jmp dtDone

dtCoin:
        ; A coin is a 6 x 10 bar in the middle of the tile.
        mov ax, [bp+8]
        add ax, 5
        push ax
        mov ax, [bp+6]
        add ax, 3
        push ax
        push word 6
        push word 10
        mov al, [tileFill + bx]
        mov ah, 0
        push ax
        call ClippedFill
        jmp dtDone

dtFlag:
        ; The flag pole is a 2 pixel line in the middle of the tile.
        mov ax, [bp+8]
        add ax, 7
        push ax
        push word [bp+6]
        push word 2
        push word 16
        mov al, [tileFill + bx]
        mov ah, 0
        push ax
        call ClippedFill

dtDone:
        pop bx
        pop ax
        pop bp
        ret 6


; DrawMap
; Draws the visible part of the working map (rows 1 to 11; row 0 is
; the HUD), scrolled by cameraX.
; The first column is cameraX / 16, and it starts at screen x =
; -(cameraX mod 16), so part of it can be hidden on the left. That
; is what makes the level scroll one pixel at a time. 21 columns are
; drawn: 20 that fit on screen plus the partly visible one.
; Changes no registers.
DrawMap:
        push ax
        push bx
        push cx
        push dx
        push si
        push di

        mov ax, [cameraX]
        mov si, ax
        shr si, 4                   ; SI = first column
        and ax, 15
        neg ax
        mov di, ax                  ; DI = screen x of that column
        mov cx, 21                  ; columns to draw

dmColumn:
        cmp si, mapCols
        jae dmDone                  ; past the end of the level
        mov dx, 1                   ; DX = row, starting below the HUD

dmRow:
        mov bx, dx
        shl bx, 1
        mov bx, [rowOffset + bx]
        add bx, si                  ; BX = row*60 + column
        mov al, [workingMap + bx]
        mov ah, 0
        cmp ax, tileSky
        je dmNextRow

        push di                     ; screen x
        mov bx, dx
        shl bx, 4
        push bx                     ; screen y = row * 16
        push ax                     ; tile code
        call DrawTile

dmNextRow:
        inc dx
        cmp dx, mapRows
        jb dmRow

        inc si
        add di, tileSize
        dec cx
        jnz dmColumn

dmDone:
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        ret