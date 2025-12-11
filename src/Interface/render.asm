TITLE Raycasting Render Module

INCLUDE Irvine32.inc

; External C functions (C calling convention)
InitOpenGL PROTO C
UpdateDisplay PROTO C
DrawWallColumn PROTO C, column:DWORD, wallHeight:DWORD, wallType:DWORD, textureX:DWORD
DrawFloorCeiling PROTO C
CloseRenderWindow PROTO C

; External game data
EXTERN playerX:DWORD, playerY:DWORD, dir:DWORD
EXTERN MazeMap:BYTE, N:DWORD

PUBLIC render
PUBLIC InitRender
PUBLIC CloseRender

.DATA
; Screen dimensions
SCREEN_WIDTH  DWORD 640
SCREEN_HEIGHT DWORD 480

; Raycasting variables
mapX DWORD ?
mapY DWORD ?
stepX SDWORD ?
stepY SDWORD ?
side DWORD ?
perpWallDist DWORD ?
lineHeight DWORD ?
wallType DWORD ?

; Constants
MAX_DEPTH DWORD 32

.CODE

; Initialize the rendering system
InitRender PROC
    INVOKE InitOpenGL
    RET
InitRender ENDP

; Cleanup rendering system
CloseRender PROC
    INVOKE CloseRenderWindow
    RET
CloseRender ENDP

; Main rendering procedure (simplified raycaster)
render PROC USES EAX EBX ECX EDX ESI EDI
    LOCAL rayDirX:SDWORD, rayDirY:SDWORD
    LOCAL cameraX:SDWORD
    LOCAL column:DWORD
    
    ; Draw floor and ceiling first
    INVOKE DrawFloorCeiling
    
    ; Get player direction (0=up, 1=right, 2=down, 3=left)
    MOV EAX, dir
    AND EAX, 3
    MOV ESI, EAX                  ; ESI = direction index
    
    ; Set base direction vectors based on player direction
    ; We'll calculate ray direction for each column
    
    ; Loop through each screen column
    MOV column, 0
    
column_loop:
    MOV EAX, column
    MOV EBX, SCREEN_WIDTH
    CMP EAX, EBX
    JAE done_rendering
    
    ; Calculate camera X (-1000 to +1000 range for fixed point)
    ; cameraX = (2 * column / SCREEN_WIDTH) - 1
    ; Using fixed point: (2000 * column / SCREEN_WIDTH) - 1000
    MOV EAX, column
    MOV EBX, 2000
    XOR EDX, EDX
    MUL EBX                       ; EAX = column * 2000
    MOV EBX, SCREEN_WIDTH
    DIV EBX                       ; EAX = (column * 2000) / SCREEN_WIDTH
    SUB EAX, 1000
    MOV cameraX, EAX              ; cameraX ranges from -1000 to +1000
    
    ; Calculate ray direction based on player direction
    ; Simplified: we'll use direction + camera offset
    CMP ESI, 0                    ; North (up)
    JE ray_north
    CMP ESI, 1                    ; East (right)
    JE ray_east
    CMP ESI, 2                    ; South (down)
    JE ray_south
    JMP ray_west                  ; West (left)
    
ray_north:
    MOV EAX, cameraX
    MOV rayDirX, EAX              ; Ray sweeps left-right
    MOV rayDirY, -1000            ; Looking north (negative Y)
    JMP setup_dda
    
ray_east:
    MOV rayDirX, 1000             ; Looking east (positive X)
    MOV EAX, cameraX
    MOV rayDirY, EAX              ; Ray sweeps up-down
    JMP setup_dda
    
ray_south:
    MOV EAX, cameraX
    NEG EAX
    MOV rayDirX, EAX              ; Ray sweeps right-left
    MOV rayDirY, 1000             ; Looking south (positive Y)
    JMP setup_dda
    
ray_west:
    MOV rayDirX, -1000            ; Looking west (negative X)
    MOV EAX, cameraX
    NEG EAX
    MOV rayDirY, EAX              ; Ray sweeps down-up
    
setup_dda:
    ; Setup DDA - simplified integer version
    ; Start at player position
    MOV EAX, playerX
    MOV mapX, EAX
    MOV EAX, playerY
    MOV mapY, EAX
    
    ; Determine step direction
    MOV EAX, rayDirX
    TEST EAX, EAX
    JGE step_x_positive
    MOV stepX, -1
    JMP setup_step_y
step_x_positive:
    MOV stepX, 1
    
setup_step_y:
    MOV EAX, rayDirY
    TEST EAX, EAX
    JGE step_y_positive
    MOV stepY, -1
    JMP dda_init
step_y_positive:
    MOV stepY, 1
    
dda_init:
    ; DDA algorithm - step through grid
    MOV wallType, 0
    MOV ECX, MAX_DEPTH            ; Max ray depth
    
dda_step:
    ; Determine which direction to step
    ; Simplified: alternate X and Y steps based on ray direction magnitude
    MOV EAX, rayDirX
    TEST EAX, EAX
    JGE abs_ray_x
    NEG EAX
abs_ray_x:
    MOV EBX, rayDirY
    TEST EBX, EBX
    JGE abs_ray_y
    NEG EBX
abs_ray_y:
    
    ; If |rayDirX| > |rayDirY|, step in X more often
    CMP EAX, EBX
    JG step_in_x
    
step_in_y:
    MOV side, 1
    MOV EAX, mapY
    ADD EAX, stepY
    MOV mapY, EAX
    JMP check_hit
    
step_in_x:
    MOV side, 0
    MOV EAX, mapX
    ADD EAX, stepX
    MOV mapX, EAX
    
check_hit:
    ; Check bounds
    MOV EAX, mapX
    CMP EAX, 1
    JL hit_wall
    MOV EBX, N
    CMP EAX, EBX
    JGE hit_wall
    
    MOV EAX, mapY
    CMP EAX, 1
    JL hit_wall
    MOV EBX, N
    CMP EAX, EBX
    JGE hit_wall
    
    ; Calculate array index: (mapY - 1) * N + (mapX - 1)
    MOV EAX, mapY
    DEC EAX
    MOV EBX, N
    XOR EDX, EDX
    MUL EBX                       ; EAX = (mapY - 1) * N
    MOV EBX, mapX
    DEC EBX
    ADD EAX, EBX                  ; EAX = index
    
    ; Get cell value
    MOV EBX, OFFSET MazeMap
    MOVZX EDX, BYTE PTR [EBX + EAX]
    MOV wallType, EDX
    
    ; Check if wall (type 1)
    CMP EDX, 1
    JE hit_wall
    
    ; Continue stepping
    DEC ECX
    JNZ dda_step
    
    ; No wall found - use default
    MOV wallType, 0
    MOV perpWallDist, 1000
    JMP calc_done
    
hit_wall:
    ; Calculate distance (simplified)
    ; Distance = difference in X or Y (depending on which side hit)
    CMP side, 0
    JE dist_x_side
    
dist_y_side:
    MOV EAX, mapY
    MOV EBX, playerY
    SUB EAX, EBX
    JMP abs_dist
    
dist_x_side:
    MOV EAX, mapX
    MOV EBX, playerX
    SUB EAX, EBX
    
abs_dist:
    TEST EAX, EAX
    JGE dist_positive
    NEG EAX
dist_positive:
    CMP EAX, 0
    JNE dist_ok
    MOV EAX, 1                    ; Prevent division by zero
dist_ok:
    MOV perpWallDist, EAX
    
calc_done:
    ; Calculate wall height
    ; lineHeight = SCREEN_HEIGHT / distance
    MOV EAX, SCREEN_HEIGHT
    XOR EDX, EDX
    MOV EBX, perpWallDist
    DIV EBX
    
    ; Cap at screen height
    MOV EBX, SCREEN_HEIGHT
    CMP EAX, EBX
    JLE height_valid
    MOV EAX, EBX
height_valid:
    MOV lineHeight, EAX
    
    ; Draw this column
    MOV EAX, column
    MOV EBX, lineHeight
    MOV ECX, wallType
    XOR EDX, EDX                  ; textureX = 0
    
    INVOKE DrawWallColumn, EAX, EBX, ECX, EDX
    
    ; Next column
    INC column
    JMP column_loop
    
done_rendering:
    INVOKE UpdateDisplay
    
    RET
render ENDP

END