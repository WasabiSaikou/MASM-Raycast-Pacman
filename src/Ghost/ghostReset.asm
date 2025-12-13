TITLE GhostReset
INCLUDE Irvine32.inc

EXTERN ghostX:DWORD, ghostY:DWORD
EXTERN targetX:DWORD, targetY:DWORD
EXTERN GHOST_MOVE_COUNTER:WORD

PUBLIC GhostReset

.code
GhostReset PROC

    mov ghostX, 26
    mov ghostY, 4

    mov targetX, 15
    mov targetY, 14

    mov GHOST_MOVE_COUNTER, 0

    ret
GhostReset ENDP

END