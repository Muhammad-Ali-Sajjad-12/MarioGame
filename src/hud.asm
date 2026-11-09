; hud.asm
; Super Mario Engine - Module 13: Heads-Up Display and Scoring (Member 1)
;
; Manages player score (32-bit), coins, and lives.
; Renders the top HUD bar (320 x 16 pixels) in VGA Mode 13h directly
; into the off-screen frame buffer (bufferSeg).
;
; Procedures:
;   AddScore    - Adds points (16-bit) to 32-bit score, clamped at 999,999.
;   AddCoin     - Adds 1 coin; awards +1 life at 100 coins (max 99 lives).
;   DrawHUD     - Draws the complete HUD bar at the top of the screen.

%ifndef MAX_LIVES
MAX_LIVES               equ 99
%endif

hudColorBlack           equ 0
hudColorRed             equ 4
hudColorBrightRed       equ 12
hudColorYellow          equ 14
hudColorWhite           equ 15
hudColorDarkGrey        equ 8

; Variables defined by Module 13 (Member 1)
scoreLo                 dw 0                ; low 16 bits of 32-bit score
scoreHi                 dw 0                ; high 16 bits of 32-bit score
coins                   db 0                ; coin counter (0 - 99)
lives                   dw 3                ; current lives count

; Note: marioHp is defined in hero.asm (db)
;       gameTime is defined in game.asm (dw)


; AddScore
; Purpose: Add points to 32-bit score, clamping at 999,999 (000F:423Fh).
; Input:   push points (16-bit word), then call
; Output:  scoreLo and scoreHi updated
; Convention: Pascal/stdcall: callee cleans 2 bytes (ret 2). Registers preserved.
AddScore:
        push bp
        mov bp, sp
        push ax
        push dx

        mov ax, [bp+4]                      ; points to add
        add [scoreLo], ax
        adc word [scoreHi], 0

        ; Clamp to 999,999 (0F423Fh)
        cmp word [scoreHi], 000Fh
        ja .clamp
        jb .done
        cmp word [scoreLo], 423Fh
        jbe .done

.clamp:
        mov word [scoreHi], 000Fh
        mov word [scoreLo], 423Fh

.done:
        pop dx
        pop ax
        pop bp
        ret 2


; AddCoin
; Purpose: Add 1 coin. At 100 coins, reset to 0 and award +1 life (max 99).
; Input:   None
; Output:  coins and lives updated
; Convention: Registers preserved, ret
AddCoin:
        push ax

        inc byte [coins]
        cmp byte [coins], 100
        jb .done

        mov byte [coins], 0
        cmp word [lives], MAX_LIVES
        jae .done
        inc word [lives]

.done:
        pop ax
        ret


; DrawHUD / DrawHud
; Purpose: Render the entire HUD overlay in the top 16 rows of bufferSeg.
; Input:   None
; Output:  HUD rendered into frame buffer
; Convention: Preserves all general registers.
DrawHud:
DrawHUD:
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        push bp
        push es
        push ds

        ; 1. Clear top 16 rows to black (y=0..15, width=320)
        push word 0                         ; x
        push word 0                         ; y
        push word screenWidth               ; width = 320
        push word 16                        ; height = 16
        push word hudColorBlack             ; color = 0
        call FillRect

        ; 2. Section 1: "MARIO" and 6-digit score
        ; Title at (x=12, y=2)
        push word 12                        ; x
        push word 2                         ; y
        push word hudStrMario               ; string
        push word hudColorWhite             ; color
        call hudDrawString

        ; 6-digit score at (x=12, y=9)
        push word 12                        ; x
        push word 9                         ; y
        push word [scoreHi]                 ; high word
        push word [scoreLo]                 ; low word
        push word hudColorWhite             ; color
        call hudDrawScore6

        ; 3. Section 2: Coin icon and count "x00"
        ; Coin glyph at (x=84, y=9)
        push word 84                        ; x
        push word 9                         ; y
        push word hudGlyphCoin              ; glyph
        push word hudColorYellow            ; color
        call hudDrawGlyph

        ; "x" at (x=94, y=9)
        push word 94                        ; x
        push word 9                         ; y
        push word hudStrX                   ; string
        push word hudColorWhite             ; color
        call hudDrawString

        ; 2-digit coins at (x=102, y=9)
        xor ax, ax
        mov al, [coins]
        push word 102                       ; x
        push word 9                         ; y
        push ax                             ; value
        push word 2                         ; 2 digits
        push word hudColorWhite             ; color
        call hudDrawNumber

        ; 4. Section 3: "WORLD" and "1-1"
        ; Title at (x=148, y=2)
        push word 148                       ; x
        push word 2                         ; y
        push word hudStrWorld               ; string
        push word hudColorWhite             ; color
        call hudDrawString

        ; "1-1" at (x=156, y=9)
        push word 156                       ; x
        push word 9                         ; y
        push word hudStr1Dash1              ; string
        push word hudColorWhite             ; color
        call hudDrawString

        ; 5. Section 4: "TIME" and 3-digit time
        ; Title at (x=216, y=2)
        push word 216                       ; x
        push word 2                         ; y
        push word hudStrTime                ; string
        push word hudColorWhite             ; color
        call hudDrawString

        ; 3-digit time at (x=224, y=9)
        push word 224                       ; x
        push word 9                         ; y
        push word [gameTime]                ; value from game.asm
        push word 3                         ; 3 digits
        push word hudColorWhite             ; color
        call hudDrawNumber

        ; 6. Section 5: Health hearts (y=2) and Lives count (y=9)
        ; Heart 1 at x=276, Heart 2 at x=286
        ; If marioHp >= 1: Heart 1 filled, else empty
        mov si, hudGlyphHeartEmpty
        cmp byte [marioHp], 1
        jb .drawHeart1
        mov si, hudGlyphHeartFilled
.drawHeart1:
        push word 276
        push word 2
        push si
        push word hudColorBrightRed
        call hudDrawGlyph

        ; If marioHp >= 2: Heart 2 filled, else empty
        mov si, hudGlyphHeartEmpty
        cmp byte [marioHp], 2
        jb .drawHeart2
        mov si, hudGlyphHeartFilled
.drawHeart2:
        push word 286
        push word 2
        push si
        push word hudColorBrightRed
        call hudDrawGlyph

        ; Lives at (x=272, y=9): "x" + lives
        push word 272                       ; x
        push word 9                         ; y
        push word hudStrLivesPrefix         ; "x"
        push word hudColorWhite             ; color
        call hudDrawString

        push word 282                       ; x
        push word 9                         ; y
        push word [lives]                   ; value
        push word 2                         ; 2 digits
        push word hudColorWhite             ; color
        call hudDrawNumber

        pop ds
        pop es
        pop bp
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        ret


; ==============================================================================
; Internal Drawing Helpers
; ==============================================================================

; hudDrawGlyph
; Purpose: Draws an 8x8 1-bit bitmap to [bufferSeg]. Set bits get color, 0 bits transparent.
; Input:   push x, push y, push glyphOffset, push color, call
; Pop:     ret 8
hudDrawGlyph:
        push bp
        mov bp, sp
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        push es

        mov es, [bufferSeg]

        ; Calculate screen buffer address: y * 320 + x
        mov ax, [bp+8]                      ; y
        mov bx, ax
        shl ax, 8
        shl bx, 6
        add ax, bx
        add ax, [bp+10]                     ; + x
        mov di, ax

        mov si, [bp+6]                      ; glyph offset (8 bytes)
        mov dl, [bp+4]                      ; color

        mov cx, 8                           ; 8 rows
.rowLoop:
        push di
        mov al, [si]                        ; 8 pixel bits for current row
        mov bh, 8                           ; 8 pixels across
.pixelLoop:
        test al, 80h                        ; test high bit
        jz .skipPixel
        mov [es:di], dl                     ; write colored pixel
.skipPixel:
        shl al, 1                           ; next bit
        inc di                              ; next screen column
        dec bh
        jnz .pixelLoop

        pop di
        add di, screenWidth                 ; next screen row (+320)
        inc si                              ; next glyph row byte
        loop .rowLoop

        pop es
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        pop bp
        ret 8


; hudDrawString
; Purpose: Draws a null-terminated string of 8x8 characters.
; Input:   push x, push y, push strOffset, push color, call
; Pop:     ret 8
hudDrawString:
        push bp
        mov bp, sp
        push ax
        push bx
        push cx
        push dx
        push si

        mov dx, [bp+10]                     ; current x
        mov si, [bp+6]                      ; string pointer

.charLoop:
        lodsb                               ; al = next character
        or al, al
        jz .done

        ; Get glyph pointer in BX
        push ax
        call hudGetCharGlyph
        mov bx, ax                          ; glyph pointer

        ; Draw this character
        push dx                             ; x
        push word [bp+8]                    ; y
        push bx                             ; glyph offset
        push word [bp+4]                    ; color
        call hudDrawGlyph

        add dx, 8                           ; advance x by 8 pixels
        jmp .charLoop

.done:
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        pop bp
        ret 8


; hudGetCharGlyph
; Purpose: Look up the 8-byte font bitmap for an ASCII character in AL.
; Input:   AL = ASCII character (pushed on stack: [bp+4])
; Output:  AX = pointer to 8-byte bitmap
; Pop:     ret 2
hudGetCharGlyph:
        push bp
        mov bp, sp
        push bx

        mov al, [bp+4]

        ; Check digits '0' - '9'
        cmp al, '0'
        jb .checkLetters
        cmp al, '9'
        ja .checkLetters
        sub al, '0'
        xor ah, ah
        shl ax, 3                           ; * 8 bytes per glyph
        add ax, hudFontDigits
        jmp .found

.checkLetters:
        ; Check uppercase 'A' - 'Z'
        cmp al, 'A'
        jb .checkLower
        cmp al, 'Z'
        ja .checkLower
        sub al, 'A'
        xor ah, ah
        shl ax, 3                           ; * 8 bytes
        add ax, hudFontLetters
        jmp .found

.checkLower:
        ; Convert lowercase 'a' - 'z' to uppercase
        cmp al, 'a'
        jb .checkSymbols
        cmp al, 'z'
        ja .checkSymbols
        sub al, 'a'
        xor ah, ah
        shl ax, 3
        add ax, hudFontLetters
        jmp .found

.checkSymbols:
        cmp al, '-'
        je .isHyphen
        cmp al, ' '
        je .isSpace
        ; Fallback: space
.isSpace:
        mov ax, hudGlyphSpace
        jmp .found
.isHyphen:
        mov ax, hudGlyphHyphen
        jmp .found

.found:
        pop bx
        pop bp
        ret 2


; hudDrawScore6
; Purpose: Prints 32-bit score as a 6-digit zero-padded number (e.g. 000100).
; Input:   push x, push y, push scoreHi, push scoreLo, push color, call
; Pop:     ret 10
hudDrawScore6:
        push bp
        mov bp, sp
        push ax
        push bx
        push cx
        push dx
        push si
        push di

        mov ax, [bp+6]                      ; low word
        mov bx, [bp+8]                      ; high word
        mov cx, 6                           ; 6 digits

        ; Sub-divide 32-bit (BX:AX) by 10 six times, pushing digits on stack
.divLoop:
        ; 1. High word divided by 10
        push ax                             ; save low word
        xor dx, dx
        mov ax, bx                          ; AX = high word
        mov di, 10
        div di                              ; AX = high quotient, DX = high remainder
        mov bx, ax                          ; new high word in BX

        ; 2. Low word divided by 10 (with high remainder in DX)
        pop ax                              ; restore low word into AX (DX:AX is dividend)
        div di                              ; AX = low quotient, DX = remainder digit (0-9)!

        push dx                             ; save extracted digit
        loop .divLoop

        ; Now pop and draw all 6 digits from left to right
        mov cx, 6
        mov dx, [bp+12]                     ; x position

.drawLoop:
        pop ax                              ; pop digit (0-9)
        shl ax, 3                           ; * 8 bytes
        add ax, hudFontDigits               ; glyph pointer

        push dx                             ; x
        push word [bp+10]                   ; y
        push ax                             ; glyph
        push word [bp+4]                    ; color
        call hudDrawGlyph

        add dx, 8                           ; advance x by 8
        loop .drawLoop

        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        pop bp
        ret 10


; hudDrawNumber
; Purpose: Prints a 16-bit number with a specified digit count (zero-padded).
; Input:   push x, push y, push value, push digitCount, push color, call
; Pop:     ret 10
hudDrawNumber:
        push bp
        mov bp, sp
        push ax
        push bx
        push cx
        push dx
        push di

        mov ax, [bp+8]                      ; value
        mov cx, [bp+6]                      ; digit count
        mov bx, 10

.extractLoop:
        xor dx, dx
        div bx                              ; AX = quotient, DX = digit (0-9)
        push dx                             ; push digit
        loop .extractLoop

        mov cx, [bp+6]                      ; digit count
        mov dx, [bp+12]                     ; x

.renderLoop:
        pop ax                              ; pop digit
        shl ax, 3
        add ax, hudFontDigits

        push dx                             ; x
        push word [bp+10]                   ; y
        push ax                             ; glyph
        push word [bp+4]                    ; color
        call hudDrawGlyph

        add dx, 8
        loop .renderLoop

        pop di
        pop dx
        pop cx
        pop bx
        pop ax
        pop bp
        ret 10


; ==============================================================================
; Text and Bitmap Data
; ==============================================================================

hudStrMario:            db "MARIO", 0
hudStrWorld:            db "WORLD", 0
hudStrTime:             db "TIME", 0
hudStr1Dash1:           db "1-1", 0
hudStrX:                db "x", 0
hudStrLivesPrefix:      db "x", 0

hudGlyphSpace:          times 8 db 0

hudGlyphHyphen:
        db 00000000b
        db 00000000b
        db 00000000b
        db 01111110b
        db 01111110b
        db 00000000b
        db 00000000b
        db 00000000b

hudGlyphCoin:
        db 00111100b
        db 01111110b
        db 01100110b
        db 01100110b
        db 01100110b
        db 01111110b
        db 00111100b
        db 00000000b

hudGlyphHeartFilled:
        db 01100110b
        db 11111111b
        db 11111111b
        db 11111111b
        db 01111110b
        db 00111100b
        db 00011000b
        db 00000000b

hudGlyphHeartEmpty:
        db 01100110b
        db 10011001b
        db 10000001b
        db 10000001b
        db 01000010b
        db 00100100b
        db 00011000b
        db 00000000b

; Digits 0 to 9 (each 8 bytes)
hudFontDigits:
        ; '0'
        db 00111100b
        db 01100110b
        db 01101110b
        db 01110110b
        db 01100110b
        db 01100110b
        db 00111100b
        db 00000000b
        ; '1'
        db 00011000b
        db 00111000b
        db 00011000b
        db 00011000b
        db 00011000b
        db 00011000b
        db 00111100b
        db 00000000b
        ; '2'
        db 00111100b
        db 01100110b
        db 00000110b
        db 00001100b
        db 00011000b
        db 00110000b
        db 01111110b
        db 00000000b
        ; '3'
        db 00111100b
        db 01100110b
        db 00000110b
        db 00011100b
        db 00000110b
        db 01100110b
        db 00111100b
        db 00000000b
        ; '4'
        db 00001100b
        db 00011100b
        db 00101100b
        db 01001100b
        db 01111110b
        db 00001100b
        db 00001100b
        db 00000000b
        ; '5'
        db 01111110b
        db 01100000b
        db 01111100b
        db 00000110b
        db 00000110b
        db 01100110b
        db 00111100b
        db 00000000b
        ; '6'
        db 00111100b
        db 01100000b
        db 01111100b
        db 01100110b
        db 01100110b
        db 01100110b
        db 00111100b
        db 00000000b
        ; '7'
        db 01111110b
        db 00000110b
        db 00001100b
        db 00011000b
        db 00110000b
        db 00110000b
        db 00110000b
        db 00000000b
        ; '8'
        db 00111100b
        db 01100110b
        db 01100110b
        db 00111100b
        db 01100110b
        db 01100110b
        db 00111100b
        db 00000000b
        ; '9'
        db 00111100b
        db 01100110b
        db 01100110b
        db 00111110b
        db 00000110b
        db 00000110b
        db 00111100b
        db 00000000b

; Uppercase Letters A to Z (each 8 bytes)
hudFontLetters:
        ; 'A'
        db 00111100b, 01100110b, 01100110b, 01111110b, 01100110b, 01100110b, 01100110b, 00000000b
        ; 'B'
        db 01111100b, 01100110b, 01100110b, 01111100b, 01100110b, 01100110b, 01111100b, 00000000b
        ; 'C'
        db 00111100b, 01100110b, 01100000b, 01100000b, 01100000b, 01100110b, 00111100b, 00000000b
        ; 'D'
        db 01111000b, 01101100b, 01100110b, 01100110b, 01100110b, 01101100b, 01111000b, 00000000b
        ; 'E'
        db 01111110b, 01100000b, 01100000b, 01111100b, 01100000b, 01100000b, 01111110b, 00000000b
        ; 'F'
        db 01111110b, 01100000b, 01100000b, 01111100b, 01100000b, 01100000b, 01100000b, 00000000b
        ; 'G'
        db 00111100b, 01100110b, 01100000b, 01101110b, 01100110b, 01100110b, 00111100b, 00000000b
        ; 'H'
        db 01100110b, 01100110b, 01100110b, 01111110b, 01100110b, 01100110b, 01100110b, 00000000b
        ; 'I'
        db 00111100b, 00011000b, 00011000b, 00011000b, 00011000b, 00011000b, 00111100b, 00000000b
        ; 'J'
        db 00011110b, 00000110b, 00000110b, 00000110b, 00000110b, 01100110b, 00111100b, 00000000b
        ; 'K'
        db 01100110b, 01101100b, 01111000b, 01110000b, 01111000b, 01101100b, 01100110b, 00000000b
        ; 'L'
        db 01100000b, 01100000b, 01100000b, 01100000b, 01100000b, 01100000b, 01111110b, 00000000b
        ; 'M'
        db 01100011b, 01110111b, 01111111b, 01101011b, 01100011b, 01100011b, 01100011b, 00000000b
        ; 'N'
        db 01100110b, 01110110b, 01111110b, 01111110b, 01101110b, 01100110b, 01100110b, 00000000b
        ; 'O'
        db 00111100b, 01100110b, 01100110b, 01100110b, 01100110b, 01100110b, 00111100b, 00000000b
        ; 'P'
        db 01111100b, 01100110b, 01100110b, 01111100b, 01100000b, 01100000b, 01100000b, 00000000b
        ; 'Q'
        db 00111100b, 01100110b, 01100110b, 01100110b, 01101110b, 00111100b, 00000110b, 00000000b
        ; 'R'
        db 01111100b, 01100110b, 01100110b, 01111100b, 01101100b, 01100110b, 01100110b, 00000000b
        ; 'S'
        db 00111100b, 01100110b, 01100000b, 00111100b, 00000110b, 01100110b, 00111100b, 00000000b
        ; 'T'
        db 01111110b, 00011000b, 00011000b, 00011000b, 00011000b, 00011000b, 00011000b, 00000000b
        ; 'U'
        db 01100110b, 01100110b, 01100110b, 01100110b, 01100110b, 01100110b, 00111100b, 00000000b
        ; 'V'
        db 01100110b, 01100110b, 01100110b, 01100110b, 01100110b, 00111100b, 00011000b, 00000000b
        ; 'W'
        db 01100011b, 01100011b, 01100011b, 01101011b, 01111111b, 01110111b, 01100011b, 00000000b
        ; 'X'
        db 01100110b, 01100110b, 00111100b, 00011000b, 00111100b, 01100110b, 01100110b, 00000000b
        ; 'Y'
        db 01100110b, 01100110b, 01100110b, 00111100b, 00011000b, 00011000b, 00011000b, 00000000b
        ; 'Z'
        db 01111110b, 00000110b, 00001100b, 00011000b, 00110000b, 01100000b, 01111110b, 00000000b
