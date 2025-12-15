TITLE Raycasting Render Module

INCLUDE Irvine32.inc

; C functions for rendering only
InitOpenGL PROTO C
UpdateDisplay PROTO C
DrawWallColumn PROTO C, column:DWORD, wallHeight:DWORD, wallType:DWORD, brightness:DWORD
DrawCeiling PROTO C
DrawFloorPixel PROTO C, column:DWORD, y:DWORD, color:DWORD
DrawHUD PROTO C, playerX:DWORD, playerY:DWORD, points:DWORD, lives:DWORD, gameState:DWORD
DrawMinimap PROTO C, mazeMap:PTR BYTE, mazeSize:DWORD, playerX:DWORD, playerY:DWORD, ghostX:DWORD, ghostY:DWORD
CloseRenderWindow PROTO C

EXTERN playerX:DWORD, playerY:DWORD, dir:DWORD, point:DWORD
EXTERN ghostX:DWORD, ghostY:DWORD
EXTERN MazeMap:BYTE, N:DWORD
EXTERN gameStateFlag:DWORD

PUBLIC render
PUBLIC InitRender
PUBLIC CloseRender

.DATA
SCREEN_WIDTH  DWORD 800
SCREEN_HEIGHT DWORD 600
SCALE DWORD 10000  ; Fixed point scale for precision
FLOOR_Y_START DWORD ?

.CODE

InitRender PROC
    INVOKE InitOpenGL
    RET
InitRender ENDP

CloseRender PROC
    INVOKE CloseRenderWindow
    RET
CloseRender ENDP

; Helper: Integer square root approximation
isqrt PROC uses EBX ECX EDX, value:DWORD
    MOV EAX, value
    MOV EBX, EAX
    SHR EBX, 1
    
    CMP EAX, 0
    JE sqrt_zero
    
    MOV ECX, 10  ; Iterations
sqrt_loop:
    MOV EAX, value
    XOR EDX, EDX
    DIV EBX
    ADD EAX, EBX
    SHR EAX, 1
    MOV EBX, EAX
    LOOP sqrt_loop
    
    MOV EAX, EBX
    RET
    
sqrt_zero:
    XOR EAX, EAX
    RET
isqrt ENDP

render PROC USES EBX ECX EDX ESI EDI
    LOCAL column:DWORD
    LOCAL rayDirX:SDWORD, rayDirY:SDWORD
    LOCAL mapX:SDWORD, mapY:SDWORD
    LOCAL deltaDistX:DWORD, deltaDistY:DWORD
    LOCAL sideDistX:DWORD, sideDistY:DWORD
    LOCAL stepX:SDWORD, stepY:SDWORD
    LOCAL hit:DWORD, side:DWORD
    LOCAL perpWallDist:DWORD
    LOCAL lineHeight:DWORD
    LOCAL cameraX:SDWORD
    LOCAL dirX:SDWORD, dirY:SDWORD
    LOCAL planeX:SDWORD, planeY:SDWORD
    LOCAL posX:DWORD, posY:DWORD
    LOCAL temp:DWORD
    LOCAL brightness:DWORD
    
    INVOKE DrawCeiling
    
    ; Player position (0-31 converted to 0.5-31.5 in fixed point)
    MOV EAX, playerX
    MOV EBX, SCALE
    IMUL EBX
    MOV EBX, SCALE
    SHR EBX, 1
    ADD EAX, EBX  ; Add 0.5
    MOV posX, EAX
    
    MOV EAX, playerY
    MOV EBX, SCALE
    IMUL EBX
    MOV EBX, SCALE
    SHR EBX, 1
    ADD EAX, EBX
    MOV posY, EAX
    
    ; Set direction vectors based on player direction
    MOV EAX, dir
    AND EAX, 3
    
    CMP EAX, 0
    JE dir_north
    CMP EAX, 1
    JE dir_east
    CMP EAX, 2
    JE dir_south
    JMP dir_west
    
dir_north:
    MOV dirX, 0
    MOV dirY, -10000
    MOV planeX, 10000
    MOV planeY, 0
    JMP start_columns
    
dir_east:
    MOV dirX, 10000
    MOV dirY, 0
    MOV planeX, 0
    MOV planeY, 10000
    JMP start_columns
    
dir_south:
    MOV dirX, 0
    MOV dirY, 10000
    MOV planeX, -10000
    MOV planeY, 0
    JMP start_columns
    
dir_west:
    MOV dirX, -10000
    MOV dirY, 0
    MOV planeX, 0
    MOV planeY, -10000
    
start_columns:
    MOV column, 0
    
column_loop:
    MOV EAX, column
    CMP EAX, SCREEN_WIDTH
    JAE done_rendering
    
    ; Calculate cameraX: maps column 0..799 to -0.5..0.5 (in fixed point: -5000..5000)
    MOV EAX, column
    MOV EBX, 10000
    IMUL EBX
    XOR EDX, EDX
    DIV SCREEN_WIDTH
    SUB EAX, 5000
    MOV cameraX, EAX
    
    ; rayDirX = dirX + planeX * cameraX / 10000
    MOV EAX, planeX
    IMUL cameraX
    MOV EBX, 10000
    CDQ
    IDIV EBX
    ADD EAX, dirX
    MOV rayDirX, EAX
    
    ; rayDirY = dirY + planeY * cameraX / 10000
    MOV EAX, planeY
    IMUL cameraX
    MOV EBX, 10000
    CDQ
    IDIV EBX
    ADD EAX, dirY
    MOV rayDirY, EAX
    
    ; Current map position
    MOV EAX, posX
    XOR EDX, EDX
    DIV SCALE
    MOV mapX, EAX
    
    MOV EAX, posY
    XOR EDX, EDX
    DIV SCALE
    MOV mapY, EAX
    
    ; Calculate deltaDistX = abs(SCALE / rayDirX)
    MOV EAX, rayDirX
    TEST EAX, EAX
    JZ raydir_x_zero
    
    MOV EBX, SCALE
    IMUL EBX, SCALE
    MOV temp, EBX
    
    MOV EAX, rayDirX
    TEST EAX, EAX
    JNS abs_rayx
    NEG EAX
abs_rayx:
    MOV EBX, EAX
    MOV EAX, temp
    XOR EDX, EDX
    DIV EBX
    MOV deltaDistX, EAX
    
    ; stepX and sideDistX
    CMP rayDirX, 0
    JL raydir_x_neg
    
    MOV stepX, 1
    MOV EAX, mapX
    INC EAX
    IMUL SCALE
    SUB EAX, posX
    IMUL deltaDistX
    DIV SCALE
    MOV sideDistX, EAX
    JMP calc_y
    
raydir_x_neg:
    MOV stepX, -1
    MOV EAX, posX
    MOV EBX, mapX
    IMUL EBX, SCALE
    SUB EAX, EBX
    IMUL deltaDistX
    DIV SCALE
    MOV sideDistX, EAX
    JMP calc_y
    
raydir_x_zero:
    MOV deltaDistX, 7FFFFFFFH
    MOV sideDistX, 7FFFFFFFH
    MOV stepX, 0
    
calc_y:
    MOV EAX, rayDirY
    TEST EAX, EAX
    JZ raydir_y_zero
    
    MOV EBX, SCALE
    IMUL EBX, SCALE
    MOV temp, EBX
    
    MOV EAX, rayDirY
    TEST EAX, EAX
    JNS abs_rayy
    NEG EAX
abs_rayy:
    MOV EBX, EAX
    MOV EAX, temp
    XOR EDX, EDX
    DIV EBX
    MOV deltaDistY, EAX
    
    CMP rayDirY, 0
    JL raydir_y_neg
    
    MOV stepY, 1
    MOV EAX, mapY
    INC EAX
    IMUL SCALE
    SUB EAX, posY
    IMUL deltaDistY
    DIV SCALE
    MOV sideDistY, EAX
    JMP dda_loop
    
raydir_y_neg:
    MOV stepY, -1
    MOV EAX, posY
    MOV EBX, mapY
    IMUL EBX, SCALE
    SUB EAX, EBX
    IMUL deltaDistY
    DIV SCALE
    MOV sideDistY, EAX
    JMP dda_loop
    
raydir_y_zero:
    MOV deltaDistY, 7FFFFFFFH
    MOV sideDistY, 7FFFFFFFH
    MOV stepY, 0
    
dda_loop:
    MOV hit, 0
    MOV ECX, 100
    
dda_step:
    ; Compare sideDist
    MOV EAX, sideDistX
    CMP EAX, sideDistY
    JL step_x
    
    ; Step Y
    MOV EAX, sideDistY
    ADD EAX, deltaDistY
    MOV sideDistY, EAX
    MOV EAX, stepY
    ADD mapY, EAX
    MOV side, 1
    JMP check_hit
    
step_x:
    ; Step X
    MOV EAX, sideDistX
    ADD EAX, deltaDistX
    MOV sideDistX, EAX
    MOV EAX, stepX
    ADD mapX, EAX
    MOV side, 0
    
check_hit:
    ; Bounds check
    MOV EAX, mapX
    TEST EAX, EAX
    JS wall_hit
    CMP EAX, N
    JAE wall_hit
    
    MOV EAX, mapY
    TEST EAX, EAX
    JS wall_hit
    CMP EAX, N
    JAE wall_hit
    
    ; Check maze
    MOV EAX, mapY
    IMUL N
    ADD EAX, mapX
    
    LEA ESI, MazeMap
    MOVZX EBX, BYTE PTR [ESI + EAX]
    
    CMP EBX, 1
    JE wall_hit
    
    DEC ECX
    JNZ dda_step
    JMP no_wall
    
wall_hit:
    MOV hit, 1
    
no_wall:
    ; Calculate perpendicular wall distance
    CMP side, 0
    JE calc_perp_x
    
    ; side == 1 (Y)
    MOV EAX, sideDistY
    SUB EAX, deltaDistY
    MOV perpWallDist, EAX
    JMP calc_height
    
calc_perp_x:
    ; side == 0 (X)
    MOV EAX, sideDistX
    SUB EAX, deltaDistX
    MOV perpWallDist, EAX
    
calc_height:
    ; lineHeight = SCREEN_HEIGHT * SCALE / perpWallDist
    MOV EAX, SCREEN_HEIGHT
    IMUL SCALE
    XOR EDX, EDX
    
    MOV EBX, perpWallDist
    CMP EBX, 100
    JGE perp_ok
    MOV EBX, 100
perp_ok:
    DIV EBX
    
    CMP EAX, 4000
    JLE height_ok
    MOV EAX, 4000
height_ok:
    MOV lineHeight, EAX
    
    ; Calculate brightness (distance-based shading)
    ; brightness = 255 / (1 + dist^2 * 0.00001)
    ; Approximate: brightness = 255 * 1000 / (1000 + dist/10)
    MOV EAX, perpWallDist
    MOV EBX, 10
    XOR EDX, EDX
    DIV EBX
    ADD EAX, 1000
    
    MOV EBX, EAX
    MOV EAX, 255000
    XOR EDX, EDX
    DIV EBX
    
    CMP EAX, 255
    JLE bright_ok
    MOV EAX, 255
bright_ok:
    
    ; Darken one side for depth effect
    CMP side, 1
    JNE side_bright
    SHR EAX, 1  ; Halve brightness for Y-sides
side_bright:
    MOV brightness, EAX
    
    ; Draw only if wall hit
    CMP hit, 0
    JE skip_draw
    INVOKE DrawWallColumn, column, lineHeight, 1, brightness
skip_draw:
    
    ; Calculate where floor starts (below the wall)
    MOV EAX, SCREEN_HEIGHT
    SUB EAX, lineHeight
    SHR EAX, 1
    ADD EAX, lineHeight
    MOV FLOOR_Y_START, EAX
    
    ; Floor raycasting from wall bottom to screen bottom
    MOV EDI, FLOOR_Y_START
    CMP EDI, SCREEN_HEIGHT
    JAE skip_floor_cast
    
floor_pixel_loop:
    ; Calculate current distance from camera to floor point
    ; p = screenHeight / (2.0 * y - screenHeight)
    MOV EAX, EDI
    SHL EAX, 1              ; 2 * y
    SUB EAX, SCREEN_HEIGHT
    CMP EAX, 0
    JLE skip_floor_pixel
    
    MOV EBX, EAX
    MOV EAX, SCREEN_HEIGHT
    IMUL SCALE
    XOR EDX, EDX
    DIV EBX
    MOV temp, EAX          ; temp = p (distance to floor point)
    
    ; Calculate floor position
    ; floorX = posX + rayDirX * p
    ; floorY = posY + rayDirY * p
    MOV EAX, rayDirX
    IMUL temp
    MOV EBX, SCALE
    CDQ
    IDIV EBX
    ADD EAX, posX
    MOV EBX, EAX           ; floorX in fixed point
    
    MOV EAX, rayDirY
    IMUL temp
    MOV ECX, SCALE
    CDQ
    IDIV ECX
    ADD EAX, posY
    MOV ECX, EAX           ; floorY in fixed point
    
    ; Convert to map coordinates
    MOV EAX, EBX
    XOR EDX, EDX
    DIV SCALE
    MOV mapX, EAX          ; floor tile X
    
    MOV EAX, ECX
    XOR EDX, EDX
    DIV SCALE
    MOV mapY, EAX          ; floor tile Y
    
    ; Check bounds
    MOV EAX, mapX
    TEST EAX, EAX
    JS floor_black
    CMP EAX, N
    JAE floor_black
    
    MOV EAX, mapY
    TEST EAX, EAX
    JS floor_black
    CMP EAX, N
    JAE floor_black
    
    ; Check if ghost is on this tile (PRIORITY 1 - RED)
    MOV EAX, mapX
    CMP EAX, ghostX
    JNE check_dots
    MOV EAX, mapY
    CMP EAX, ghostY
    JNE check_dots
    
    ; Ghost tile - draw RED
    INVOKE DrawFloorPixel, column, EDI, 0FF0000h  ; Red in 0xRRGGBB format
    JMP next_floor_pixel
    
check_dots:
    ; Get maze value
    MOV EAX, mapY
    IMUL N
    ADD EAX, mapX
    LEA ESI, MazeMap
    MOVZX EBX, BYTE PTR [ESI + EAX]
    
    ; Check tile type
    CMP EBX, 2
    JE floor_yellow
    CMP EBX, 0
    JE floor_black
    
    ; Wall or unknown - draw black
    JMP floor_black
    
floor_yellow:
    ; Path with dots - draw YELLOW
    INVOKE DrawFloorPixel, column, EDI, 0FFFF00h  ; Yellow
    JMP next_floor_pixel
    
floor_black:
    ; Empty path - draw BLACK
    INVOKE DrawFloorPixel, column, EDI, 0000000h  ; Black
    JMP next_floor_pixel
    
skip_floor_pixel:
    ; If calculation error, draw black
    INVOKE DrawFloorPixel, column, EDI, 0000000h
    
next_floor_pixel:
    INC EDI
    CMP EDI, SCREEN_HEIGHT
    JL floor_pixel_loop
    
skip_floor_cast:
    
    INC column
    JMP column_loop
    
done_rendering:
    INVOKE DrawHUD, playerX, playerY, point, 3, gameStateFlag
    
    LEA EAX, MazeMap
    INVOKE DrawMinimap, EAX, N, playerX, playerY, ghostX, ghostY
    
    INVOKE UpdateDisplay
    
    RET
render ENDP

END