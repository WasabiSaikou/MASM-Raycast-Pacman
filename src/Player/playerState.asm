TITLE PlayerState

INCLUDE Irvine32.inc
PUBLIC PlayerState
PUBLIC playerX, playerY, dir, inputCode
PUBLIC moveState
PUBLIC prevX, prevY

EXTERN N:DWORD

.data
    playerX   DWORD 15
    playerY   DWORD 14
    dir       DWORD 0        ; 0=↑,1=→,2=↓,3=← (CHANGED TO 0 = UP)
    inputCode DWORD 0        ; 0=none, 1~7
    moveState DWORD 0        ; 0 = stop, 1 = front, 2 = left, 3 = behind, 4 = right
    prevX     DWORD 15
    prevY     DWORD 14

.code
PlayerState PROC
    mov eax, playerX
    mov ebx, playerY
    mov ecx, dir
    ret
PlayerState ENDP

END