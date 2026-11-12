; camera.asm
; Module 6: Camera and Scrolling
; Muhammad Ali Sajjad (25F-0105)
;
; cameraX is the world x position of the left edge of the screen. The
; level is 960 pixels wide but the screen shows only 320, so anything
; in the world is drawn at screen x = world x - cameraX.
; The rules come from manual Section 5.3: the camera follows Mario once
; he passes the middle of the screen, it never scrolls back, it stops
; at the end of the level, and Mario cannot walk off the left edge of
; the screen.

cameraFollowX   equ 160                     ; Mario's screen x where scrolling starts
cameraMaxX      equ levelWidth - screenWidth    ; 640, the last camera position

cameraX         dw 0


; UpdateCamera
; Applies the camera rules once per frame, after Mario has moved.
; Only whole pixels are used, so the picture never jitters.
; 1. screen x = marioX - cameraX
; 2. if that is more than 160, the new camera is marioX - 160
; 3. the new camera is at most 640
; 4. the camera only moves right, never back
; 5. Mario is not allowed left of cameraX (the left wall)
; Example: cameraX = 100 and marioX = 270 give screen x 170, so the
; camera moves to 270 - 160 = 110.
; Changes no registers.
UpdateCamera:
        push ax

        mov ax, [marioX]
        sub ax, [cameraX]           ; Mario's screen x
        cmp ax, cameraFollowX
        jle ucLeftWall              ; not past the middle yet

        mov ax, [marioX]
        sub ax, cameraFollowX       ; new camera position
        cmp ax, cameraMaxX
        jle ucNotPastEnd
        mov ax, cameraMaxX          ; stop at the end of the level
ucNotPastEnd:
        cmp ax, [cameraX]
        jle ucLeftWall              ; never scroll back
        mov [cameraX], ax

ucLeftWall:
        mov ax, [marioX]
        cmp ax, [cameraX]
        jge ucDone
        mov ax, [cameraX]           ; push him back to the screen edge
        mov [marioX], ax
        mov byte [marioXSub], 0
        mov word [marioVX], 0

ucDone:
        pop ax
        ret


; WorldToScreen
; Converts a world x position to a screen x position and tells whether
; a 16 pixel wide object there can be seen (-16 < screen x < 320).
; Use it before drawing anything that lives in the level.
; Input:  push world x, then call
; Output: AX = screen x, CF = 0 if visible, CF = 1 if off screen
; Changes AX only.
WorldToScreen:
        push bp
        mov bp, sp

        mov ax, [bp+4]
        sub ax, [cameraX]
        cmp ax, -16
        jle wsHidden
        cmp ax, screenWidth
        jge wsHidden
        clc
        pop bp
        ret 2

wsHidden:
        stc
        pop bp
        ret 2