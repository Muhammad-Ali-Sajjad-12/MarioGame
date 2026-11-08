; hero.asm
; Module 9: Player Movement and Physics
;
; Mario's data and his movement rules from manual Section 5.2: walk,
; run, friction, jump, variable jump height and gravity.
;
; Speeds are 8.8 fixed point words. Positions need more room because
; the level is 960 pixels wide, so each position is a whole pixel word
; plus a separate fraction byte (marioX with marioXSub). Adding a speed
; adds the fractions first, and the carry from that addition moves
; Mario one more whole pixel.

marioXSub       db 0                ; fraction of x (1/256 pixel)
marioX          dw startX           ; world x of the sprite's left edge
marioYSub       db 0                ; fraction of y
marioY          dw startY           ; world y of the sprite's top edge
marioVX         dw 0                ; horizontal speed, positive = right
marioVY         dw 0                ; vertical speed, positive = down
marioHeight     dw heightSmall      ; 16 when Small, 32 when Super
marioForm       db formSmall
marioHp         db 1                ; 1 when Small, 2 when Super
onGround        db 1                ; 1 while standing on a solid tile
facing          db faceRight        ; direction of the last key pressed
marioPose       db poseStand
invulnTimer     db 0                ; frames of blinking left after a hit
stompChain      db 0                ; stomps during the current jump
jumpLatch       db 1                ; 1 means Space must be released first
prevFeetY       dw startY + heightSmall     ; feet y at the start of this frame
marioDead       db deathNone        ; set to deathPit when he falls in a pit
flagTouched     db 0                ; 1 when he touches the flag pole
flagRow         db 0                ; map row of his feet at that moment


; ResetHero
; Puts Mario back at the start of the level as Small Mario. Used for
; every new life and new game (Section 5.8).
; Changes no registers.
ResetHero:
        mov byte [marioXSub], 0
        mov word [marioX], startX
        mov byte [marioYSub], 0
        mov word [marioY], startY
        mov word [prevFeetY], startY + heightSmall
        mov word [marioVX], 0
        mov word [marioVY], 0
        mov word [marioHeight], heightSmall
        mov byte [marioForm], formSmall
        mov byte [marioHp], 1
        mov byte [onGround], 1
        mov byte [facing], faceRight
        mov byte [marioPose], poseStand
        mov byte [invulnTimer], 0
        mov byte [stompChain], 0
        mov byte [jumpLatch], 1     ; a held Space will not jump by itself
        mov byte [marioDead], deathNone
        mov byte [flagTouched], 0
        mov byte [flagRow], 0
        ret


; UpdateVelocity
; Applies the movement rules of Section 5.2 once per frame.
; Horizontal: the held direction key speeds Mario up to the walking
; limit, or the running limit while Left Shift is held. With no
; direction key, friction slows him down to zero. Pressing the other
; direction brakes him twice as fast as friction.
; Vertical: Space starts a jump only while standing on the ground and
; only after Space was released since the last jump, so there is no
; jump in mid-air and no automatic repeat jump. Releasing Space while
; still rising fast cuts the jump short. Gravity is added every frame
; up to the maximum fall speed.
; Changes no registers.
UpdateVelocity:
        push ax
        push bx

        ; Speed limit: walking, or running while Left Shift is held.
        mov bx, maxWalk
        cmp byte [keyTable + keyLeftShift], 0
        je uvLimitSet
        mov bx, maxRun
uvLimitSet:
        mov ax, [marioVX]

        cmp byte [keyTable + keyRight], 0
        jne uvRight
        cmp byte [keyTable + keyLeft], 0
        jne uvLeft

        ; No direction key: friction pulls the speed towards zero
        ; without letting it cross over to the other direction.
        cmp ax, 0
        je uvClamp
        jl uvSlowLeft
        sub ax, friction
        jge uvClamp
        mov ax, 0
        jmp uvClamp
uvSlowLeft:
        add ax, friction
        jle uvClamp
        mov ax, 0
        jmp uvClamp

uvRight:
        mov byte [facing], faceRight
        add ax, walkAccel
        jmp uvClamp
uvLeft:
        mov byte [facing], faceLeft
        sub ax, walkAccel

uvClamp:
        ; Keep the speed between -limit and +limit.
        cmp ax, bx
        jle uvNotTooFast
        mov ax, bx
uvNotTooFast:
        neg bx
        cmp ax, bx
        jge uvSpeedDone
        mov ax, bx
uvSpeedDone:
        mov [marioVX], ax

        ; Jump: only from the ground, and only if Space was released
        ; since the last jump.
        cmp byte [keyTable + keySpace], 0
        je uvSpaceReleased
        cmp byte [onGround], 1
        jne uvGravity
        cmp byte [jumpLatch], 0
        jne uvGravity
        mov word [marioVY], jumpSpeed
        mov byte [onGround], 0
        mov byte [jumpLatch], 1
        jmp uvGravity

uvSpaceReleased:
        mov byte [jumpLatch], 0
        ; Variable jump height: if Mario is still rising faster than
        ; the cut-off speed, slow him down to it.
        cmp word [marioVY], jumpCutoff
        jge uvGravity
        mov word [marioVY], jumpCutoff

uvGravity:
        mov ax, [marioVY]
        add ax, gravity
        cmp ax, maxFall
        jle uvFallOk
        mov ax, maxFall
uvFallOk:
        mov [marioVY], ax

        pop bx
        pop ax
        ret


; SetPose
; Chooses the sprite pose: jumping while in the air, running while
; moving on the ground, otherwise standing.
; Changes no registers.
SetPose:
        cmp byte [onGround], 1
        je spOnGround
        mov byte [marioPose], poseJump
        ret
spOnGround:
        cmp word [marioVX], 0
        je spStand
        mov byte [marioPose], poseRun
        ret
spStand:
        mov byte [marioPose], poseStand
        ret


; SetForm
; Changes Mario to Small or Super while keeping his feet where they
; are: the new top is the feet position minus the new height (Section
; 5.1). Used by the mushroom (Module 12) and when he gets hurt.
; Input:  push formSmall or formSuper, then call
; Changes no registers.
SetForm:
        push bp
        mov bp, sp
        push ax

        mov ax, [marioY]
        add ax, [marioHeight]       ; AX = y of his feet, stays the same

        cmp word [bp+4], formSuper
        je sfSuper
        mov byte [marioForm], formSmall
        mov byte [marioHp], 1
        mov word [marioHeight], heightSmall
        jmp sfKeepFeet
sfSuper:
        mov byte [marioForm], formSuper
        mov byte [marioHp], 2
        mov word [marioHeight], heightSuper

sfKeepFeet:
        sub ax, [marioHeight]       ; new top = feet - new height
        mov [marioY], ax

        pop ax
        pop bp
        ret 2

; UpdateMario
; Step 3 of every frame (Section 5.13). Remembers where his feet were,
; applies the movement rules, moves him one axis at a time with tile
; collision, keeps him inside the level, checks the pit and the flag
; pole and picks his pose.
; Changes no registers.
UpdateMario:
        push ax

        mov ax, [marioY]
        add ax, [marioHeight]
        mov [prevFeetY], ax         ; used by the stomp test

        call UpdateVelocity
        call MoveX
        call MoveY
        call ClampToLevel
        call CheckPitAndFlag
        call SetPose

        pop ax
        ret