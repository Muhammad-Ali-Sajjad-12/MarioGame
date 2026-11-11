; Bonus Module: PC Speaker Sound Effects (Member 3)

; SoundMute
; Purpose: Turn off PC speaker tone output
; Inputs: None
; Outputs: Speaker muted
; Registers changed: None
SoundMute:
    push ax
    in al, 61h
    and al, 0FCh
    out 61h, al
    pop ax
    ret

; PlayTone
; Purpose: Play a tone on the PC speaker using PIT Channel 2
; Inputs: [bp+4] = frequency divisor
; Outputs: Speaker enabled with requested frequency
; Registers changed: None
PlayTone:
    push bp
    mov bp, sp
    push ax

    ; set PIT Channel 2 to square wave mode (0B6h)
    mov al, 0B6h
    out 43h, al

    ; send low byte and high byte of divisor to port 42h
    mov ax, [bp + 4]
    out 42h, al
    mov al, ah
    out 42h, al

    ; turn on speaker bits 0 and 1 on port 61h
    in al, 61h
    or al, 03h
    out 61h, al

    pop ax
    pop bp
    ret 2

; Short sound effect wrappers for game events
SoundJump:
    push word 2200
    call PlayTone
    ret

SoundCoin:
    push word 1200
    call PlayTone
    ret

SoundStomp:
    push word 4500
    call PlayTone
    ret

SoundKick:
    push word 3000
    call PlayTone
    ret

SoundBreakBrick:
    push word 5000
    call PlayTone
    ret

SoundBump:
    push word 6000
    call PlayTone
    ret

SoundPowerupAppear:
    push word 1800
    call PlayTone
    ret

SoundPowerup:
    push word 1400
    call PlayTone
    ret

SoundPipeDown:
    push word 3500
    call PlayTone
    ret

Sound1Up:
    push word 1000
    call PlayTone
    ret

SoundDeath:
    push word 5500
    call PlayTone
    ret

SoundFlag:
    push word 1500
    call PlayTone
    ret
