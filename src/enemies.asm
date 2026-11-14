; Module 11: Enemies and Shell Mechanics

; Enemy types
ENEMY_NONE          equ 0
ENEMY_GOOMBA        equ 1
ENEMY_KOOPA         equ 2
ENEMY_SHELL         equ 3

; Enemy states
ESTATE_INACTIVE     equ 0           ; waiting until it comes near the screen
ESTATE_ACTIVE       equ 1           ; walking
ESTATE_FLAT         equ 2           ; stomped Goomba, removed when timer ends
ESTATE_STATIONARY   equ 3           ; shell standing still
ESTATE_SLIDING      equ 4           ; shell kicked and sliding

; Enemy record layout (16 bytes per enemy)
REC_TYPE            equ 0           ; byte
REC_STATE           equ 1           ; byte
REC_TIMER           equ 2           ; byte
REC_DIR             equ 3           ; byte, 0 = left, 1 = right
REC_X               equ 4           ; word, world x
REC_Y               equ 6           ; word, world y
REC_VX              equ 8           ; word, 8.8 fixed point speed
REC_VY              equ 10          ; word, 8.8 fixed point speed
REC_SUB_X           equ 12          ; word, fraction of x
REC_SUB_Y           equ 14          ; word, fraction of y
ENEMY_REC_SIZE      equ 16
MAX_ACTIVE_ENEMIES  equ 8

; Speeds and timers (Section 5.5, Appendix A.4 and A.5)
GOOMBA_SPEED        equ 0080h       ; 0.5 px/frame
KOOPA_SPEED         equ 00C0h       ; 0.75 px/frame
SHELL_SLIDE_SPEED   equ 0300h       ; 3 px/frame
GRAVITY_ACCEL       equ 0040h       ; 0.25 px/frame per frame
MAX_FALL_SPEED      equ 0400h       ; 4 px/frame
STOMP_BOUNCE_SPEED  equ -0300h      ; -3 px/frame
FLAT_GOOMBA_FRAMES  equ 30          ; about 1 second
SHELL_GRACE_FRAMES  equ 8           ; kick grace time
INVULN_FRAMES       equ 60          ; about 2 seconds
SMALL_HITBOX_H      equ 16          ; height of Small Mario
PIT_DEATH_Y         equ 192         ; below the map

; Stomp chain points (Section 5.4), the 11th stomp gives a 1-UP
stomp_score_table:
    dw 100, 200, 400, 500, 800, 1000, 2000, 4000, 5000, 8000

; Start of the level: 4 Goombas and 2 Koopas on row 9 (y = 144),
; all waiting and facing left. The last two slots are empty.
; Each line: type, state, timer, dir, x, y, vx, vy, sub_x, sub_y
initial_enemies_data:
    db ENEMY_GOOMBA, ESTATE_INACTIVE, 0, 0
    dw 256, 144, -GOOMBA_SPEED, 0, 0, 0
    db ENEMY_GOOMBA, ESTATE_INACTIVE, 0, 0
    dw 464, 144, -GOOMBA_SPEED, 0, 0, 0
    db ENEMY_GOOMBA, ESTATE_INACTIVE, 0, 0
    dw 544, 144, -GOOMBA_SPEED, 0, 0, 0
    db ENEMY_KOOPA, ESTATE_INACTIVE, 0, 0
    dw 592, 144, -KOOPA_SPEED, 0, 0, 0
    db ENEMY_GOOMBA, ESTATE_INACTIVE, 0, 0
    dw 640, 144, -GOOMBA_SPEED, 0, 0, 0
    db ENEMY_KOOPA, ESTATE_INACTIVE, 0, 0
    dw 752, 144, -KOOPA_SPEED, 0, 0, 0
    db ENEMY_NONE, ESTATE_INACTIVE, 0, 0
    dw 0, 0, 0, 0, 0, 0
    db ENEMY_NONE, ESTATE_INACTIVE, 0, 0
    dw 0, 0, 0, 0, 0, 0

; Working copy of the table, filled by ResetEnemies
enemies_table:
    times MAX_ACTIVE_ENEMIES * ENEMY_REC_SIZE db 0

; ResetEnemies
; Purpose: Copy initial enemy records into working enemies_table
; Inputs: None
; Outputs: enemies_table restored
; Registers changed: None
ResetEnemies:
    push ax
    push cx
    push si
    push di
    push es

    push ds
    pop es
    mov si, initial_enemies_data
    mov di, enemies_table
    mov cx, (MAX_ACTIVE_ENEMIES * ENEMY_REC_SIZE) / 2
    cld
    rep movsw

    pop es
    pop di
    pop si
    pop cx
    pop ax
    ret

; UpdateEnemies
; Purpose: Update movement, collisions, shells, and Mario interactions for all enemies
; Inputs: None
; Outputs: Updates enemies_table, Mario state, and score
; Registers changed: None
UpdateEnemies:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, enemies_table
    mov cx, MAX_ACTIVE_ENEMIES

.enemy_loop:
    push cx
    cmp byte [si + REC_TYPE], ENEMY_NONE
    je .next_enemy

    ; decrease enemy timer if active
    cmp byte [si + REC_TIMER], 0
    je .check_flat
    dec byte [si + REC_TIMER]

.check_flat:
    ; remove flattened Goomba when its timer reaches 0
    cmp byte [si + REC_STATE], ESTATE_FLAT
    jne .check_activation
    cmp byte [si + REC_TIMER], 0
    jne .next_enemy
    jmp .despawn_enemy

.check_activation:
    mov ax, [si + REC_X]
    sub ax, [cameraX]

    cmp byte [si + REC_STATE], ESTATE_INACTIVE
    jne .is_active

    ; start walking when within 1 tile of screen right edge
    cmp ax, 336
    jge .next_enemy
    mov byte [si + REC_STATE], ESTATE_ACTIVE

.is_active:
    ; remove enemy if it falls into a pit or goes far left of camera
    cmp word [si + REC_Y], PIT_DEATH_Y
    jae .despawn_enemy
    cmp ax, -32
    jl .despawn_enemy

    ; stationary shell does not move
    cmp byte [si + REC_STATE], ESTATE_STATIONARY
    je .check_mario_interaction

    ; apply gravity to vertical speed
    mov ax, [si + REC_VY]
    add ax, GRAVITY_ACCEL
    cmp ax, MAX_FALL_SPEED
    jle .save_vy
    mov ax, MAX_FALL_SPEED
.save_vy:
    mov [si + REC_VY], ax

    ; update horizontal position (8.8 fixed point)
    mov ax, [si + REC_SUB_X]
    add ax, [si + REC_VX]
    mov bx, ax
    sar bx, 8
    and ax, 00FFh
    mov [si + REC_SUB_X], ax
    add [si + REC_X], bx

    ; check wall in front (right side if VX > 0, left side if VX <= 0)
    mov bx, [si + REC_X]
    mov dx, [si + REC_Y]
    add dx, 8
    cmp word [si + REC_VX], 0
    jle .wall_left
    add bx, 16
    jmp .test_wall
.wall_left:
    dec bx
.test_wall:
    push bx
    push dx
    call IsSolidAt
    cmp ax, 1
    jne .check_enemy_bump

    ; hit a wall: reverse direction
    neg word [si + REC_VX]
    xor byte [si + REC_DIR], 1
    jmp .move_vertical

.check_enemy_bump:
    ; walking enemies also turn around when they meet another enemy
    cmp byte [si + REC_STATE], ESTATE_ACTIVE
    jne .check_koopa_ledge

    mov di, enemies_table
    mov cx, MAX_ACTIVE_ENEMIES
.bump_loop:
    cmp di, si
    je .next_bump
    cmp byte [di + REC_TYPE], ENEMY_NONE
    je .next_bump
    cmp byte [di + REC_STATE], ESTATE_INACTIVE
    je .next_bump
    cmp byte [di + REC_STATE], ESTATE_FLAT
    je .next_bump
    cmp byte [di + REC_STATE], ESTATE_SLIDING
    je .next_bump

    ; close enough to touch?
    mov ax, [di + REC_X]
    sub ax, [si + REC_X]
    cmp ax, -16
    jle .next_bump
    cmp ax, 16
    jge .next_bump
    mov dx, [di + REC_Y]
    sub dx, [si + REC_Y]
    cmp dx, -16
    jle .next_bump
    cmp dx, 16
    jge .next_bump

    ; turn only if walking towards the other enemy
    cmp word [si + REC_VX], 0
    jl .bump_going_left
    cmp ax, 0
    jle .next_bump
    jmp .bump_turn
.bump_going_left:
    cmp ax, 0
    jge .next_bump
.bump_turn:
    neg word [si + REC_VX]
    xor byte [si + REC_DIR], 1
    jmp .move_vertical

.next_bump:
    add di, ENEMY_REC_SIZE
    loop .bump_loop

.check_koopa_ledge:
    ; Koopa also turns around at platform edges
    cmp byte [si + REC_TYPE], ENEMY_KOOPA
    jne .move_vertical

    mov bx, [si + REC_X]
    mov dx, [si + REC_Y]
    add dx, 18
    cmp word [si + REC_VX], 0
    jle .ledge_left
    add bx, 16
    jmp .test_ledge
.ledge_left:
    sub bx, 2
.test_ledge:
    push bx
    push dx
    call IsSolidAt
    cmp ax, 1
    je .move_vertical

    neg word [si + REC_VX]
    xor byte [si + REC_DIR], 1

.move_vertical:
    ; update vertical position (8.8 fixed point)
    mov ax, [si + REC_SUB_Y]
    add ax, [si + REC_VY]
    mov dx, ax
    sar dx, 8
    and ax, 00FFh
    mov [si + REC_SUB_Y], ax
    add [si + REC_Y], dx

    ; check floor below feet
    mov bx, [si + REC_X]
    add bx, 8
    mov dx, [si + REC_Y]
    add dx, 16
    push bx
    push dx
    call IsSolidAt
    cmp ax, 1
    jne .check_shell_kills

    ; snap enemy feet to top of floor tile
    mov dx, [si + REC_Y]
    add dx, 16
    and dx, 0FFF0h
    sub dx, 16
    mov [si + REC_Y], dx
    mov word [si + REC_VY], 0
    mov word [si + REC_SUB_Y], 0

.check_shell_kills:
    ; sliding shell defeats other active enemies (+500 points)
    cmp byte [si + REC_STATE], ESTATE_SLIDING
    jne .check_mario_interaction

    mov di, enemies_table
    mov cx, MAX_ACTIVE_ENEMIES
.shell_hit_loop:
    cmp di, si
    je .next_shell_target
    cmp byte [di + REC_STATE], ESTATE_ACTIVE
    jne .next_shell_target

    mov ax, [di + REC_X]
    sub ax, [si + REC_X]
    cmp ax, -14
    jl .next_shell_target
    cmp ax, 14
    jg .next_shell_target

    mov byte [di + REC_TYPE], ENEMY_NONE
    mov byte [di + REC_STATE], ESTATE_INACTIVE
    push word 500
    call AddScore
    call SoundKick

.next_shell_target:
    add di, ENEMY_REC_SIZE
    loop .shell_hit_loop

.check_mario_interaction:
    ; horizontal overlap check between Mario and enemy
    mov ax, [marioX]
    sub ax, [si + REC_X]
    cmp ax, -12
    jle .next_enemy
    cmp ax, 12
    jge .next_enemy

    ; vertical overlap check between Mario and enemy
    mov ax, [marioY]
    mov cx, ax
    add cx, SMALL_HITBOX_H
    cmp byte [marioForm], formSuper
    jne .check_y_box
    add cx, 16
.check_y_box:
    mov bx, [si + REC_Y]
    mov dx, bx
    add dx, 16
    cmp cx, bx
    jle .next_enemy
    cmp ax, dx
    jge .next_enemy

    ; touching a stationary shell kicks it (+400 points)
    cmp byte [si + REC_STATE], ESTATE_STATIONARY
    jne .check_grace
    ; a shell that was just made by a stomp ignores Mario for a few frames
    cmp byte [si + REC_TIMER], 0
    jne .next_enemy

    mov byte [si + REC_STATE], ESTATE_SLIDING
    mov byte [si + REC_TIMER], SHELL_GRACE_FRAMES
    push word 400
    call AddScore
    call SoundKick

    mov word [si + REC_VX], SHELL_SLIDE_SPEED
    mov byte [si + REC_DIR], 1
    mov ax, [marioX]
    cmp ax, [si + REC_X]
    jle .next_enemy
    mov word [si + REC_VX], -SHELL_SLIDE_SPEED
    mov byte [si + REC_DIR], 0
    jmp .next_enemy

.check_grace:
    ; ignore sliding shell during its 8-frame kick grace period
    cmp byte [si + REC_STATE], ESTATE_SLIDING
    jne .test_stomp
    cmp byte [si + REC_TIMER], 0
    jne .next_enemy

.test_stomp:
    ; stomp succeeds if Mario is falling and his feet were above enemy center
    cmp word [marioVY], 0
    jle .hurt_mario
    mov ax, [prevFeetY]
    mov bx, [si + REC_Y]
    add bx, 8
    cmp ax, bx
    jg .hurt_mario

    ; stomp succeeded: award chain points and bounce Mario up
    call AwardStompChainPoints
    mov word [marioVY], STOMP_BOUNCE_SPEED
    call SoundStomp

    cmp byte [si + REC_TYPE], ENEMY_GOOMBA
    jne .turn_into_shell

    mov byte [si + REC_STATE], ESTATE_FLAT
    mov byte [si + REC_TIMER], FLAT_GOOMBA_FRAMES
    jmp .next_enemy

.turn_into_shell:
    mov byte [si + REC_TYPE], ENEMY_SHELL
    mov byte [si + REC_STATE], ESTATE_STATIONARY
    mov byte [si + REC_TIMER], SHELL_GRACE_FRAMES
    mov word [si + REC_VX], 0
    jmp .next_enemy

.hurt_mario:
    ; side contact: ignore if Mario is blinking (invulnerable)
    cmp byte [invulnTimer], 0
    ja .next_enemy

    ; Super Mario shrinks to Small with 2s invulnerability
    cmp byte [marioForm], formSuper
    jne .kill_mario

    add word [marioY], 16
    mov byte [marioForm], formSmall
    mov byte [marioHp], 1
    mov word [marioHeight], heightSmall
    mov byte [invulnTimer], INVULN_FRAMES
    call SoundPipeDown
    jmp .next_enemy

.kill_mario:
    call TriggerMarioDeath
    jmp .next_enemy

.despawn_enemy:
    mov byte [si + REC_TYPE], ENEMY_NONE
    mov byte [si + REC_STATE], ESTATE_INACTIVE

.next_enemy:
    pop cx
    add si, ENEMY_REC_SIZE
    dec cx
    jnz .enemy_loop

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; AwardStompChainPoints
; Purpose: Add consecutive stomp points (100..8000 or 1-UP) to score
; Inputs: None
; Outputs: Score or lives updated, stompChain incremented
; Registers changed: None
AwardStompChainPoints:
    push ax
    push bx

    xor ah, ah
    mov al, [stompChain]
    cmp al, 10
    jae .give_1up

    shl ax, 1
    mov bx, ax
    push word [stomp_score_table + bx]
    call AddScore
    jmp .done_chain

.give_1up:
    cmp word [lives], MAX_LIVES
    jae .done_chain
    inc word [lives]
    call Sound1Up

.done_chain:
    inc byte [stompChain]
    pop bx
    pop ax
    ret

; DrawEnemies
; Purpose: Draw all visible enemies and shells into the frame buffer
; Inputs: None
; Outputs: Sprites drawn to frame buffer
; Registers changed: None
DrawEnemies:
    push ax
    push bx
    push cx
    push dx
    push si

    mov si, enemies_table
    mov cx, MAX_ACTIVE_ENEMIES

.draw_loop:
    push cx
    cmp byte [si + REC_TYPE], ENEMY_NONE
    je .next_draw
    cmp byte [si + REC_STATE], ESTATE_INACTIVE
    je .next_draw

    ; compute screen_x = world_x - cameraX
    mov ax, [si + REC_X]
    sub ax, [cameraX]
    cmp ax, -16
    jle .next_draw
    cmp ax, screenWidth
    jge .next_draw

    ; select sprite bitmap based on enemy type and state
    mov bx, koopa_shell
    cmp byte [si + REC_TYPE], ENEMY_SHELL
    je .draw_now
    mov bx, koopa_walk1
    cmp byte [si + REC_TYPE], ENEMY_KOOPA
    je .draw_now
    mov bx, goomba_flat
    cmp byte [si + REC_STATE], ESTATE_FLAT
    je .draw_now
    mov bx, goomba_walk1

.draw_now:
    xor cx, cx
    cmp byte [si + REC_DIR], 1
    jne .call_sprite
    mov cx, 1

.call_sprite:
    push ax
    push word [si + REC_Y]
    push bx
    push word 16
    push word 16
    push cx
    call DrawSprite

.next_draw:
    pop cx
    add si, ENEMY_REC_SIZE
    dec cx
    jnz .draw_loop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret