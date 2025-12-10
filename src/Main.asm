TITLE Main

INCLUDE Irvine32.inc

main          EQU start@0

GetTickCount PROTO   ; Windows API: The number of milliseconds since the system started sending data back

InputModule PROTO
PlayerPos PROTO
PlayerRotate PROTO

ghostPos PROTO

collision PROTO
gameState PROTO
maze PROTO

EXTERN playerX:DWORD, playerY:DWORD, dir:DWORD, inputCode:DWORD
EXTERN ghostX:DWORD, ghostY:DWORD


.data
tickMs   DWORD 16    ; length of each tick: 16ms → approximately 60 ticks/second
lastTick DWORD 0     ; Last update time
nowTime  DWORD 0     ; now time
elapsed  DWORD 0     ; Difference from the last update

.code
main PROC

    ; Initialize lastTick
    call GetTickCount
    mov lastTick, eax

main_loop:
; --------------------------------------
;       Determine time interval
; --------------------------------------
    ; get nowTime
    call GetTickCount
    mov nowTime, eax
    
    ; calculate elapsed = nowTime - lastTick
    mov eax, nowTime
    sub eax, lastTick
    mov elapsed, eax

    ; if elapsed < tickMs → continue waiting
    mov eax, elapsed
    cmp eax, tickMs
    jb main_loop

    ; update lastTick
    mov eax, lastTick
    add eax, tickMs
    mov lastTick, eax

; --------------------------------------
;       An update of a tick begins
; --------------------------------------
    ; player
    call InputModule 
    call PlayerRotate
    call PlayerPos 

    ; ghost
    call ghostPos

    ; logic
    call Collision
    call gameState
    
    ; interface

    jmp main_loop
    
main ENDP
END main
