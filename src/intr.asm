; Modules 7 and 8: Keyboard and Timer Interrupt Handlers

; saved original interrupt vectors (offset then segment)
old_int09_off   dw 0
old_int09_seg   dw 0
old_int1c_off   dw 0
old_int1c_seg   dw 0

; key_table: 1 = key held, 0 = released, indexed by scan code
key_table       times 128 db 0

; tick_counter: increased on every timer tick (30 per second)
tick_counter    dw 0

; InstallInterrupts
; Purpose: Save old INT 09h and INT 1Ch vectors and set custom handlers
; Inputs: None
; Outputs: old_int09 and old_int1c saved, new handlers installed, timer at 30 Hz
; Registers changed: None
InstallInterrupts:
    push ax
    push bx
    push dx
    push es

    ; save old keyboard handler (INT 09h)
    mov ax, 3509h
    int 21h
    mov [old_int09_off], bx
    mov [old_int09_seg], es

    ; set new keyboard handler
    mov dx, KeyboardISR
    mov ax, 2509h
    int 21h

    ; save old timer handler (INT 1Ch)
    mov ax, 351Ch
    int 21h
    mov [old_int1c_off], bx
    mov [old_int1c_seg], es

    ; set new timer handler
    mov dx, TimerISR
    mov ax, 251Ch
    int 21h

    ; set timer rate to about 30 ticks per second (1193182 / 30 = 39772)
    mov al, 36h
    out 43h, al
    mov ax, 39772
    out 40h, al
    mov al, ah
    out 40h, al

    pop es
    pop dx
    pop bx
    pop ax
    ret

; RestoreInterrupts
; Purpose: Restore original INT 1Ch and INT 09h handlers and timer rate before exit
; Inputs: None
; Outputs: Original vectors restored
; Registers changed: None
RestoreInterrupts:
    push ax
    push dx
    push ds

    ; set timer rate back to normal 18.2 Hz (divisor 0 = 65536)
    mov al, 36h
    out 43h, al
    mov al, 0
    out 40h, al
    out 40h, al

    ; restore old timer handler
    ; cs: is used because ds is changed below
    mov dx, [cs:old_int1c_off]
    mov ds, [cs:old_int1c_seg]
    mov ax, 251Ch
    int 21h

    ; restore old keyboard handler
    mov dx, [cs:old_int09_off]
    mov ds, [cs:old_int09_seg]
    mov ax, 2509h
    int 21h

    pop ds
    pop dx
    pop ax
    ret

; KeyboardISR
; Purpose: Read scan code from port 60h and update key_table
; Inputs: None
; Outputs: Updates key_table (1 = held, 0 = released)
; Registers changed: None
KeyboardISR:
    push ax
    push bx
    push ds

    push cs
    pop ds

    ; read scan code from keyboard port
    in al, 60h

    ; ignore E0h prefix from arrow keys
    cmp al, 0E0h
    je .done

    ; get 7-bit scan code as index in BX
    mov bl, al
    and bl, 7Fh
    xor bh, bh

    ; bit 7 is 0 for press, 1 for release
    test al, 80h
    jnz .released

    mov byte [key_table + bx], 1
    jmp .done

.released:
    mov byte [key_table + bx], 0

.done:
    ; send end of interrupt (EOI) to PIC
    mov al, 20h
    out 20h, al

    pop ds
    pop bx
    pop ax
    iret

; TimerISR
; Purpose: Increment tick_counter on every timer tick, then chain to old handler
; Inputs: None
; Outputs: tick_counter incremented
; Registers changed: None
TimerISR:
    inc word [cs:tick_counter]
    ; continue into the original INT 1Ch handler
    jmp far [cs:old_int1c_off]