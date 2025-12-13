TITLE Main

INCLUDE Irvine32.inc

main          EQU start@0

GetTickCount PROTO

InputModule PROTO
PlayerPos PROTO
PlayerRotate PROTO

ghostPos PROTO

collision PROTO
collisionGhost PROTO
gameState PROTO
maze PROTO

render2D PROTO
InitRender PROTO

EXTERN playerX:DWORD, playerY:DWORD, dir:DWORD, inputCode:DWORD
EXTERN ghostX:DWORD, ghostY:DWORD
EXTERN targetX:DWORD, targetY:DWORD
EXTERN gameStateFlag:DWORD, resultDisplayTimer:DWORD

PUBLIC tickMs

.data
tickMs   DWORD 100
lastTick DWORD 0
nowTime  DWORD 0
elapsed  DWORD 0

.code

main PROC
    call Clrscr
    
    call GetTickCount
    mov lastTick, eax
    call InitRender

main_loop:
; --------------------------------------
;       Timing
; --------------------------------------
    call GetTickCount
    mov nowTime, eax
    
    mov eax, nowTime
    sub eax, lastTick
    mov elapsed, eax

    cmp eax, tickMs
    jb main_loop

    mov eax, nowTime
    mov lastTick, eax

; --------------------------------------
;       Game Logic Update
; --------------------------------------
    mov eax, gameStateFlag
    cmp eax, 5
    je do_reset
    cmp eax, 3
    je check_win_input
    cmp eax, 4
    je check_lose_input
    jmp do_game_update

check_win_input:
check_lose_input:
    call InputModule
    mov eax, inputCode
    cmp eax, 0
    je render_frame
    
    mov gameStateFlag, 5
    jmp render_frame

do_reset:
    call gameState
    jmp render_frame

do_game_update:
    call InputModule
    
    mov eax, inputCode
    cmp eax, 7
    je trigger_reset
    
    call PlayerRotate
    call PlayerPos 
    call collision

    ; Update ghost target to current player position
    mov eax, playerX
    mov targetX, eax
    mov eax, playerY
    mov targetY, eax

    ; Ghost with BFS pathfinding
    call ghostPos

    call collisionGhost
    call gameState
    jmp render_frame

trigger_reset:
    mov gameStateFlag, 5
    jmp render_frame

; --------------------------------------
;       ALWAYS Render Every Frame
; --------------------------------------
render_frame:
    call render2D
    jmp main_loop
    
main ENDP
END main