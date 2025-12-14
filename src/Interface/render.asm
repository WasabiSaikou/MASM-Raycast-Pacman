TITLE Raycasting Render Module

INCLUDE Irvine32.inc

; C functions for rendering only
InitOpenGL PROTO C
UpdateDisplay PROTO C
DrawWallColumn PROTO C, column:DWORD, wallHeight:DWORD, wallType:DWORD, brightness:DWORD
DrawFloorCeiling PROTO C
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
    
    INVOKE DrawFloorCeiling
    
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
    
    MOV EBX, 7
    IMUL EBX
    MOV EBX, 10
    XOR EDX, EDX
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