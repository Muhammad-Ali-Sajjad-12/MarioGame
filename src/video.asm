; video.asm
; Module 2: Video and Colours (Member 1)
;
; VGA mode 13h is 320 x 200 pixels with one byte per pixel, so the pixel
; at (x, y) is at offset y * 320 + x. The colour byte is an index into
; the palette of 256 colours.
;
; Drawing goes into the segment stored in bufferSeg. It starts as the
; screen itself (A000h). The game calls InitBuffer (Module 5), which
; points it to an off-screen frame buffer instead. Every frame is drawn
; there, and ShowBuffer copies it to the screen in one go, so the player
; never sees a half drawn picture.
;
; Procedures here:
;   InitVideo          sets mode 13h and the palette
;   SetPaletteColour   changes one palette entry
;   PutPixel           draws one pixel (off-screen pixels are ignored)
;   FillRect           fills a rectangle (the caller keeps it on screen)

; Colours. 0 to 15 are the default VGA colours and are not changed, the
; other members already use them. 32 and up are our own colours.
colourBlack     equ 0
colourBlue      equ 1
colourGreen     equ 2
colourRed       equ 4
colourBrown     equ 6
colourGrey      equ 7
colourSky       equ 9               ; light blue
colourYellow    equ 14
colourWhite     equ 15
colourSkin      equ 32
colourDarkBrown equ 33
colourCream     equ 34

videoSeg        equ 0A000h          ; segment of the screen in mode 13h
bufferParas     equ 4000            ; 64,000 bytes in paragraphs of 16 bytes
bufferWords     equ 32000           ; 64,000 bytes as 16-bit words
paletteIndex    equ 3C8h            ; port: which palette entry to change
paletteData     equ 3C9h            ; port: red, then green, then blue

; The segment that PutPixel, FillRect and ClearBuffer work on.
bufferSeg       dw videoSeg


; InitVideo
; Purpose: Switch to mode 13h and set our colours
; Inputs: None   Outputs: None   Registers changed: None
InitVideo:
        push ax
        mov ax, 0013h               ; AH = 0 (set video mode), AL = 13h
        int 10h
        call InitPalette
        pop ax
        ret


; InitPalette
; Purpose: Set our own colours (red, green and blue are 0 to 63 each)
; Inputs: None   Outputs: None   Registers changed: None
InitPalette:
        push word colourSkin
        push word 63
        push word 46
        push word 32
        call SetPaletteColour

        push word colourDarkBrown
        push word 32
        push word 16
        push word 0
        call SetPaletteColour

        push word colourCream
        push word 63
        push word 60
        push word 50
        call SetPaletteColour
        ret


; SetPaletteColour
; Purpose: Change one entry of the VGA palette
; Inputs:  push index, push red, push green, push blue, then call
;          (red, green and blue are 0 to 63)
; Outputs: None   Registers changed: None
SetPaletteColour:
        push bp
        mov bp, sp
        push ax
        push dx

        mov dx, paletteIndex
        mov al, [bp+10]             ; index
        out dx, al                  ; choose the entry
        inc dx                      ; now the data port
        mov al, [bp+8]              ; red
        out dx, al
        mov al, [bp+6]              ; green
        out dx, al
        mov al, [bp+4]              ; blue
        out dx, al

        pop dx
        pop ax
        pop bp
        ret 8


; PutPixel
; Purpose: Draw one pixel. Pixels outside the screen are ignored.
; Inputs:  push x, push y, push colour, then call
; Outputs: None   Registers changed: None
PutPixel:
        push bp
        mov bp, sp
        push ax
        push bx
        push di
        push es

        mov ax, [bp+8]              ; x
        cmp ax, screenWidth
        jae pixelDone               ; unsigned compare, so negative x is out too
        mov bx, [bp+6]              ; y
        cmp bx, screenHeight
        jae pixelDone

        ; offset = y * 320 + x, and y * 320 = y * 256 + y * 64
        mov di, bx
        shl bx, 8
        shl di, 6
        add di, bx
        add di, ax

        mov es, [bufferSeg]
        mov al, [bp+4]              ; colour
        mov [es:di], al

pixelDone:
        pop es
        pop di
        pop bx
        pop ax
        pop bp
        ret 6


; FillRect
; Purpose: Fill a rectangle with one colour. The rectangle must be on
; the screen already (ClippedFill in map.asm cuts it first).
; Inputs:  push x, push y, push width, push height, push colour, then call
; Outputs: None   Registers changed: None
FillRect:
        push bp
        mov bp, sp
        push ax
        push bx
        push cx
        push dx
        push di
        push es

        cmp word [bp+8], 0          ; nothing to draw if width or
        jle fillDone                ; height is zero or less
        cmp word [bp+6], 0
        jle fillDone

        mov es, [bufferSeg]
        mov ax, [bp+10]             ; y
        mov bx, ax
        shl ax, 8                   ; y * 256
        shl bx, 6                   ; y * 64
        add ax, bx                  ; y * 320
        add ax, [bp+12]             ; + x
        mov di, ax
        mov al, [bp+4]              ; colour
        mov dx, [bp+6]              ; rows left
        cld                         ; STOSB moves DI forward
fillRow:
        push di                     ; remember the start of this row
        mov cx, [bp+8]              ; width
        rep stosb                   ; write AL to CX pixels
        pop di
        add di, screenWidth         ; same x, next row
        dec dx
        jnz fillRow

fillDone:
        pop es
        pop di
        pop dx
        pop cx
        pop bx
        pop ax
        pop bp
        ret 10


; ---------------------------------------------------------------------
; Module 5: Frame Buffer
; ---------------------------------------------------------------------
; The screen needs 64,000 bytes, and a .COM program already owns a whole
; 64 KB segment, so the buffer must live in a second segment. DOS gives
; it to us with function 48h, but only after our program has handed back
; the memory it does not use (function 4Ah).

noMemoryText    db 'Not enough memory for the frame buffer.$'

; InitBuffer
; Purpose: Ask DOS for a second 64,000 byte segment and draw into it.
; If DOS has no memory it prints a message and ends the program.
; Call it first of all, before the interrupts are installed.
; Inputs: None   Outputs: bufferSeg = segment of the buffer
; Registers changed: None
InitBuffer:
        push ax
        push bx
        push dx
        push es

        mov ax, cs
        mov es, ax                  ; function 4Ah needs ES = our segment
        mov bx, 1000h               ; keep 1000h paragraphs = 64 KB
        mov ah, 4Ah                 ; shrink our memory block
        int 21h
        jc bufferFailed             ; carry flag set means an error

        mov bx, bufferParas         ; how much we want
        mov ah, 48h                 ; allocate a new memory block
        int 21h
        jc bufferFailed
        mov [bufferSeg], ax         ; AX = segment of the new block

        pop es
        pop dx
        pop bx
        pop ax
        ret

bufferFailed:
        mov dx, noMemoryText        ; DS = CS in a .COM program
        mov ah, 09h                 ; print the text up to the $ sign
        int 21h
        mov ax, 4C01h               ; end with error code 1
        int 21h


; ClearBuffer
; Purpose: Fill the whole frame buffer with the sky colour
; Inputs: None   Outputs: None   Registers changed: None
ClearBuffer:
        push ax
        push cx
        push di
        push es

        mov es, [bufferSeg]
        xor di, di                  ; start at the first byte
        mov al, colourSky
        mov ah, al                  ; one word = two pixels of the same colour
        mov cx, bufferWords         ; 32,000 words = 64,000 pixels
        cld
        rep stosw                   ; AX to ES:DI, CX times

        pop es
        pop di
        pop cx
        pop ax
        ret


; ShowBuffer
; Purpose: Copy the frame buffer to the screen. It first waits for the
; start of the vertical retrace (bit 3 of port 3DAh), so the picture
; changes while the monitor is not drawing and does not tear.
; Inputs: None   Outputs: None   Registers changed: None
ShowBuffer:
        push ax
        push cx
        push dx
        push si
        push di
        push ds
        push es

        mov dx, 03DAh               ; VGA status port
waitRetraceEnd:
        in al, dx
        test al, 8
        jnz waitRetraceEnd          ; a retrace is running, let it finish
waitRetraceStart:
        in al, dx
        test al, 8
        jz waitRetraceStart         ; wait for the next one to begin

        mov ax, videoSeg
        mov es, ax                  ; destination: the screen
        mov ax, [bufferSeg]
        mov ds, ax                  ; source: the frame buffer
        xor si, si
        xor di, di
        mov cx, bufferWords
        cld
        rep movsw                   ; DS:SI to ES:DI, CX words

        pop es
        pop ds
        pop di
        pop si
        pop dx
        pop cx
        pop ax
        ret
