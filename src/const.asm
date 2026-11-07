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