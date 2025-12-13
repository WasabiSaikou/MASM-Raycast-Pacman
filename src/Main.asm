TITLE Main

INCLUDE Irvine32.inc

main          EQU start@0

GetTickCount PROTO   ; Windows API: The number of milliseconds since the system started sending data back

InputModule PROTO
PlayerPos PROTO
PlayerRotate PROTO

ghostPos PROTO
Init_Node_Map PROTO

collision PROTO
collisionGhost PROTO
gameState PROTO
maze PROTO

;render PROTO
render2D PROTO
InitRender PROTO

EXTERN playerX:DWORD, playerY:DWORD, dir:DWORD, inputCode:DWORD
EXTERN ghostX:DWORD, ghostY:DWORD
EXTERN inputCode:DWORD
EXTERN gameStateFlag:DWORD, resultDisplayTimer:DWORD

;PUBLIC waitToStartFlag
PUBLIC tickMs

.data
tickMs   DWORD 100        ; length of each tick: 16ms → approximately 60 ticks/second
lastTick DWORD 0         ; Last update time
nowTime  DWORD 0         ; now time
elapsed  DWORD 0         ; Difference from the last update
;waitToStartFlag DWORD 1
;pressStartMsg BYTE "Press any key to start !", 0

.code

main PROC

    ; Initialize lastTick
    call GetTickCount
    mov lastTick, eax
    call InitRender

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
;      An update of a tick begins
; --------------------------------------

    ; check if is playing
    ; 0: playing, 3、4: show message for one second, 5: reset game
    mov eax, gameStateFlag
    cmp eax, 5
    je resetAll
    cmp eax, 3
    je checkDisplay
    cmp eax, 4
    je checkDisplay

    ; check if is waiting for game start
;    mov eax, waitToStartFlag
;    cmp eax, 1
;    je waitForStart

gameUpdate:
    call Clrscr

    ; player
    call InputModule 
    call PlayerRotate
    call PlayerPos 
    ; check if player hit the wall
    call collision

    ; ghost
    call Init_Node_Map
    call ghostPos

    ; logic
    call collisionGhost
    call gameState
    
    jmp renderSection

; before begin the game
;waitForStart:
;    mov edx, OFFSET pressStartMsg
;    call WriteString
;    call Crlf

;    call ReadKey
;    call Clrscr
    
;   xor eax, eax
;    mov waitToStartFlag, eax
;    jmp renderSection


checkDisplay:
    ; when player win or lose will show message for 1 second
    mov eax, resultDisplayTimer
    cmp eax, 0
    jle resultEnd

    ; resultDisplayTimer = resultDisplayTimer - tickMs (16)
    sub eax, tickMs
    mov resultDisplayTimer, eax

    jmp renderSection

resultEnd:
    ; end 1 second
    mov gameStateFlag, 5
    jmp nextLoop

resetAll:
    call gameState
    jmp nextLoop

renderSection:
    ; interface
    ; call render
    call render2D

nextLoop:
    jmp main_loop
    
main ENDP
END main
