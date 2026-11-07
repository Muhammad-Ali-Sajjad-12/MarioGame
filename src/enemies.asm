; Module 11: Enemies and Shell Mechanics

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
    sub ax, [camera_x]

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
    call GetTile
    call IsTileSolid
    jne .check_koopa_ledge

    ; hit a wall: reverse direction
    neg word [si + REC_VX]
    xor byte [si + REC_DIR], 1
    jmp .move_vertical

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
    call GetTile
    call IsTileSolid
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
    call GetTile
    call IsTileSolid
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
    mov ax, [mario_x]
    sub ax, [si + REC_X]
    cmp ax, -12
    jle .next_enemy
    cmp ax, 12
    jge .next_enemy

    ; vertical overlap check between Mario and enemy
    mov ax, [mario_y]
    mov cx, ax
    add cx, SMALL_HITBOX_H
    cmp byte [mario_form], FORM_SUPER
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

    mov byte [si + REC_STATE], ESTATE_SLIDING
    mov byte [si + REC_TIMER], SHELL_GRACE_FRAMES
    push word 400
    call AddScore
    call SoundKick

    mov word [si + REC_VX], SHELL_SLIDE_SPEED
    mov byte [si + REC_DIR], 1
    mov ax, [mario_x]
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
    cmp word [mario_vy], 0
    jle .hurt_mario
    mov ax, [mario_prev_feet_y]
    mov bx, [si + REC_Y]
    add bx, 8
    cmp ax, bx
    jg .hurt_mario

    ; stomp succeeded: award chain points and bounce Mario up
    call AwardStompChainPoints
    mov word [mario_vy], STOMP_BOUNCE_SPEED
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
    cmp byte [mario_invuln_timer], 0
    ja .next_enemy

    ; Super Mario shrinks to Small with 2s invulnerability
    cmp byte [mario_form], FORM_SUPER
    jne .kill_mario

    add word [mario_y], 16
    mov byte [mario_form], FORM_SMALL
    mov byte [mario_hp], 1
    mov byte [mario_invuln_timer], INVULN_FRAMES
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
; Outputs: Score or lives updated, mario_stomp_chain incremented
; Registers changed: None
AwardStompChainPoints:
    push ax
    push bx

    xor ah, ah
    mov al, [mario_stomp_chain]
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
    inc byte [mario_stomp_chain]
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

    ; compute screen_x = world_x - camera_x
    mov ax, [si + REC_X]
    sub ax, [camera_x]
    cmp ax, -16
    jle .next_draw
    cmp ax, SCREEN_WIDTH
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