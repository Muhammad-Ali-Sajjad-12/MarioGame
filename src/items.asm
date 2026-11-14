; items.asm
; Module 12: Blocks, Coins and Power-ups
; Owner: Muhammad Ali Sajjad (25F-0105)
;
; What happens when Mario hits a block from below, collects a coin or
; touches the mushroom (manual Section 5.9):
;   brick       Super Mario breaks it (+50), Small Mario just bumps it
;   ? coin      a coin pops out (+200, +1 coin) and it becomes empty
;   ? mushroom  a mushroom comes out on top and it becomes empty
;   coin tile   touching it collects it (+200, +1 coin)
;   mushroom    touching it makes Small Mario Super (+1000)
; AddScore and AddCoin come from hud.asm (Member 1). AddCoin also gives
; an extra life at 100 coins. The sounds come from sound.asm (Member 3).
;
; The game calls three procedures: ResetItems at the start of every
; life, UpdateItems once per frame and DrawItems while drawing.

brickPoints     equ 50
coinPoints      equ 200
mushroomPoints  equ 1000
coinPopFrames   equ 12                  ; how long the popped coin is shown

mushActive      db 0                    ; 1 while a mushroom is in the level
mushX           dw 0                    ; world position of its top left corner
mushY           dw 0
mushYSub        db 0                    ; fraction of y
mushVY          dw 0                    ; falling speed, 8.8 fixed point
mushDir         dw 1                    ; 1 = moving right, -1 = moving left

coinPopTimer    db 0                    ; frames left of the popped coin
coinPopX        dw 0
coinPopY        dw 0


; ResetItems
; Removes the mushroom and the popped coin. Called with ResetLevel.
; Changes no registers.
ResetItems:
        mov byte [mushActive], 0
        mov byte [coinPopTimer], 0
        ret


; HitBlockAt
; Called by MoveY when Mario's head hits a solid tile. Makes the block
; at that point react.
; Input:  push px, push py (a point inside the block), then call
; Changes no registers.
HitBlockAt:
        push bp
        mov bp, sp
        push ax

        push word [bp+6]
        push word [bp+4]
        call GetTile
        cmp ax, tileBrick
        je hbBrick
        cmp ax, tileQuestionCoin
        je hbCoin
        cmp ax, tileQuestionMushroom
        je hbMushroom
        call SoundBump              ; any other block just bumps
        jmp hbDone

hbBrick:
        cmp byte [marioForm], formSuper
        je hbBreak
        call SoundBump              ; Small Mario cannot break bricks
        jmp hbDone
hbBreak:
        push word [bp+6]
        push word [bp+4]
        push word tileSky           ; the brick disappears
        call SetTile
        push word brickPoints
        call AddScore
        call SoundBreakBrick
        jmp hbDone

hbCoin:
        push word [bp+6]
        push word [bp+4]
        push word tileEmpty
        call SetTile
        push word coinPoints
        call AddScore
        call AddCoin
        call SoundCoin
        ; Show a coin rising out of the top of the block.
        mov ax, [bp+6]
        and ax, 0FFF0h              ; left edge of the block
        mov [coinPopX], ax
        mov ax, [bp+4]
        and ax, 0FFF0h
        sub ax, tileSize            ; just above the block
        mov [coinPopY], ax
        mov byte [coinPopTimer], coinPopFrames
        jmp hbDone

hbMushroom:
        push word [bp+6]
        push word [bp+4]
        push word tileEmpty
        call SetTile
        ; The mushroom appears standing on top of the block.
        mov ax, [bp+6]
        and ax, 0FFF0h
        mov [mushX], ax
        mov ax, [bp+4]
        and ax, 0FFF0h
        sub ax, tileSize
        mov [mushY], ax
        mov byte [mushYSub], 0
        mov word [mushVY], 0
        mov word [mushDir], 1       ; it starts moving right
        mov byte [mushActive], 1
        call SoundPowerupAppear

hbDone:
        pop ax
        pop bp
        ret 4


; UpdateItems
; Called once per frame: moves the popped coin and the mushroom, then
; checks whether Mario collects a coin or the mushroom.
; Changes no registers.
UpdateItems:
        cmp byte [coinPopTimer], 0
        je uiMushroom
        dec byte [coinPopTimer]
        sub word [coinPopY], 2      ; the coin rises 2 pixels per frame
uiMushroom:
        call MoveMushroom
        call CollectMapCoins
        call CheckMushroomPickup
        ret


; MoveMushroom
; The mushroom moves 1 pixel per frame, turns around at walls, falls
; off edges with the same gravity as Mario and lands on solid tiles.
; It disappears when it falls into a pit or leaves the screen on the left.
; Changes no registers.
MoveMushroom:
        push ax
        push bx
        push cx
        push dx
        push di

        cmp byte [mushActive], 0
        jne mmMove
        jmp mmDone

mmMove:
        ; Across: is there a wall where it wants to go?
        mov di, [mushX]
        add di, [mushDir]           ; DI = new x
        mov bx, di                  ; BX = x of the leading edge
        cmp word [mushDir], 0
        jl mmCheckWall
        add bx, 15
mmCheckWall:
        push bx
        push word [mushY]
        call IsSolidAt              ; top of the leading edge
        mov cx, ax
        mov dx, [mushY]
        add dx, 15
        push bx
        push dx
        call IsSolidAt              ; bottom of the leading edge
        or ax, cx
        jz mmFreeAhead
        neg word [mushDir]          ; wall: turn around
        jmp mmFall
mmFreeAhead:
        mov [mushX], di

mmFall:
        ; Down: gravity, up to the maximum fall speed.
        mov ax, [mushVY]
        add ax, gravity
        cmp ax, maxFall
        jle mmSpeedOk
        mov ax, maxFall
mmSpeedOk:
        mov [mushVY], ax
        add [mushYSub], al          ; fraction first, then whole pixels
        mov al, ah
        cbw
        adc [mushY], ax

        ; Is there a floor just below it?
        mov dx, [mushY]
        add dx, tileSize            ; first pixel row below it
        mov bx, [mushX]
        add bx, 2
        push bx
        push dx
        call IsSolidAt
        mov cx, ax
        mov bx, [mushX]
        add bx, 13
        push bx
        push dx
        call IsSolidAt
        or ax, cx
        jz mmCheckGone
        and dx, 0FFF0h              ; top of the floor tile
        sub dx, tileSize            ; stand on it
        mov [mushY], dx
        mov byte [mushYSub], 0
        mov word [mushVY], 0

mmCheckGone:
        cmp word [mushY], mapBottom
        jge mmRemove                ; fell into a pit
        mov ax, [mushX]
        add ax, tileSize
        cmp ax, [cameraX]
        jg mmDone                   ; still on the screen
mmRemove:
        mov byte [mushActive], 0

mmDone:
        pop di
        pop dx
        pop cx
        pop bx
        pop ax
        ret


; CheckMushroomPickup
; If Mario touches the mushroom it disappears, he gets 1000 points and
; Small Mario becomes Super Mario. Super Mario only gets the points.
; Changes no registers.
CheckMushroomPickup:
        push ax

        cmp byte [mushActive], 0
        je cmDone
        push word [mushX]
        push word [mushY]
        push word tileSize
        push word tileSize
        call MarioTouches
        cmp ax, 0
        je cmDone

        mov byte [mushActive], 0
        push word mushroomPoints
        call AddScore
        call SoundPowerup
        cmp byte [marioForm], formSuper
        je cmDone
        push word formSuper
        call SetForm

cmDone:
        pop ax
        ret


; CollectMapCoins
; Collects any coin tile that Mario's hitbox touches. It tests the left
; and right edges of the hitbox at his head, middle and feet.
; Changes no registers.
CollectMapCoins:
        push cx

        mov cx, [marioY]            ; head
        push cx
        call CoinsAtRow
        mov cx, [marioHeight]
        shr cx, 1
        add cx, [marioY]            ; middle
        push cx
        call CoinsAtRow
        mov cx, [marioY]
        add cx, [marioHeight]
        dec cx                      ; feet
        push cx
        call CoinsAtRow

        pop cx
        ret


; CoinsAtRow
; Helper for CollectMapCoins: takes the coins at Mario's left and
; right hitbox edges on one row.
; Input:  push y, then call
; Changes no registers.
CoinsAtRow:
        push bp
        mov bp, sp
        push bx

        mov bx, [marioX]
        add bx, hitLeft
        push bx
        push word [bp+4]
        call TakeCoinAt
        mov bx, [marioX]
        add bx, hitRight
        push bx
        push word [bp+4]
        call TakeCoinAt

        pop bx
        pop bp
        ret 2


; TakeCoinAt
; If the tile at this point is a coin, it is removed and gives
; 200 points and one coin.
; Input:  push px, push py, then call
; Changes no registers.
TakeCoinAt:
        push bp
        mov bp, sp
        push ax

        push word [bp+6]
        push word [bp+4]
        call GetTile
        cmp ax, tileCoin
        jne tcDone

        push word [bp+6]
        push word [bp+4]
        push word tileSky
        call SetTile
        push word coinPoints
        call AddScore
        call AddCoin
        call SoundCoin

tcDone:
        pop ax
        pop bp
        ret 4


; DrawItems
; Draws the mushroom and the popped coin if they are on the screen.
; Changes no registers.
DrawItems:
        push ax

        cmp byte [mushActive], 0
        je diCoin
        push word [mushX]
        call WorldToScreen          ; AX = screen x, CF = 1 if off screen
        jc diCoin
        push ax
        push word [mushY]
        push word mushroom
        push word 16
        push word 16
        push word 0
        call DrawSprite

diCoin:
        cmp byte [coinPopTimer], 0
        je diDone
        push word [coinPopX]
        call WorldToScreen
        jc diDone
        push ax
        push word [coinPopY]
        push word coin
        push word 16
        push word 16
        push word 0
        call DrawSprite

diDone:
        pop ax
        ret