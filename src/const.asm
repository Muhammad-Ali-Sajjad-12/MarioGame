; Named constants shared by all modules. This file contains only EQU
; directives so it emits no bytes It is included at the top of mario.asm

; Screen and map dimensions (Module 3)
screenWidth             equ 320
screenHeight            equ 200
tileSize                equ 16
mapCols                 equ 60
mapRows                 equ 12
mapSize                 equ mapCols * mapRows       ; 720 bytes
levelWidth              equ mapCols * tileSize      ; 960 pixels
mapBottom               equ mapRows * tileSize      ; 192 anything below is a pit

; Tile codes (Appendix A.2) Codes 1 through 10 are solid.
tileSky                 equ 0
tileGround              equ 1
tileBrick               equ 2
tileQuestionCoin        equ 3                       ; question block holding a coin
tileQuestionMushroom    equ 4                       ; question block holding a mushroom
tileEmpty               equ 5                       ; used (emptied) block
tilePipeTopLeft         equ 6
tilePipeTopRight        equ 7
tilePipeBottomLeft      equ 8
tilePipeBottomRight     equ 9
tileStair               equ 10
tileCoin                equ 11
tileFlag                equ 12

; Mario (Modules 9 and 10)
startX                  equ 32
startY                  equ 144                     ; Small Mario standing on row 9
formSmall               equ 0
formSuper               equ 1
heightSmall             equ 16
heightSuper             equ 32
hitLeft                 equ 2                       ; the hitbox is 12 pixels wide,
hitRight                equ 13                      ; from x+2 to x+13 inside the sprite
marioMaxX               equ levelWidth - 16         ; 944, right end of the level
faceRight               equ 0
faceLeft                equ 1
poseStand               equ 0
poseRun                 equ 1
poseJump                equ 2
deathNone               equ 0
deathPit                equ 1

; Physics in 8.8 fixed point, per frame at 30 frames per second (Appendix A.5).
; The high byte is whole pixels and the low byte is 1/256 of a pixel.
walkAccel               equ 0020h                   ; 0.125
friction                equ 0010h                   ; 0.0625
maxWalk                 equ 0180h                   ; 1.5
maxRun                  equ 0280h                   ; 2.5
gravity                 equ 0040h                   ; 0.25
jumpSpeed               equ -0580h                  ; -5.5 (up is negative)
jumpCutoff              equ -0200h                  ; -2.0
maxFall                 equ 0400h                   ; 4.0
stompBounce             equ -0300h                  ; -3.0

; Scan codes (Appendix A.3)
keyLeft                 equ 4Bh
keyRight                equ 4Dh
keySpace                equ 39h
keyLeftShift            equ 2Ah