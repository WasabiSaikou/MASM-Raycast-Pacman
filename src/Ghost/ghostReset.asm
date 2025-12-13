TITLE GhostReset
INCLUDE Irvine32.inc
INCLUDE AIDataStruct.inc

EXTERN ghostX:DWORD, ghostY:DWORD
EXTERN targetX:DWORD, targetY:DWORD
EXTERN GHOST_MOVE_COUNTER:WORD
EXTERN PATH_LENGTH:DWORD, CURRENT_PATH_STEP:DWORD

EXTERN Reset_A_Star:PROTO

PUBLIC GhostReset

.code
GhostReset PROC

    mov ghostX, 26
    mov ghostY, 4

    mov targetX, 15
    mov targetY, 14

    mov GHOST_MOVE_COUNTER, 0

    call Reset_A_Star

    mov PATH_LENGTH, 0
    mov CURRENT_PATH_STEP, 0

    ret
GhostReset ENDP

END