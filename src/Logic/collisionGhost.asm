TITLE collisionGhost

INCLUDE Irvine32.inc

PUBLIC collisionGhost

EXTERN playerX:DWORD, playerY:DWORD
EXTERN ghostX:DWORD, ghostY:DWORD
EXTERN gameOverFlag:DWORD

gameState PROTO 

.code
collisionGhost PROC 

    mov eax, playerX
    cmp eax, ghostX
    jne noCollision
    mov eax, playerY
    cmp eax, ghostY
    jne noCollision

    ; hit the ghost → game over
    mov ebx, 1
    mov gameOverFlag, ebx
    call gameState

noCollision:
    ret

collisionGhost ENDP
END
