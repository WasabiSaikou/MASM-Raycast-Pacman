TITLE collision

INCLUDE Irvine32.inc

PUBLIC collision

EXTERN playerX:DWORD, playerY:DWORD, point:DWORD
EXTERN prevX:DWORD, prevY:DWORD
EXTERN ghostX:DWORD, ghostY:DWORD
EXTERN MazeMap:BYTE, N:DWORD
EXTERN gameOverFlag:DWORD, gameWinFlag:DWORD

gameState PROTO 

.code
collision PROC 

    ; calculate index = N * playerY + playerX
    mov eax, playerY
    imul eax, N
    mov edx, playerX
    add eax, edx                   ; eax = index
    mov ebx, OFFSET MazeMap
    movzx ecx, BYTE PTR [ebx+eax]  ; ecx = MazeMap[index]
    
    cmp ecx, 1
    jne notHitWall

    ; Hitting the wall → Go back to the previous step
    mov eax, prevX
    mov playerX, eax
    mov eax, prevY
    mov playerY, eax
    jmp checkGhost

notHitWall:
    cmp ecx, 2
    jne checkGhost

    mov edx, point
    add edx, 1
    mov point, edx
    mov BYTE PTR [ebx+eax], 0

    ; eat all dots → win the game
    cmp edx, 361
    jne checkGhost
    mov ebx, 1
    mov gameWinFlag, ebx
    call gameState

checkGhost:
    ; Judgment of ghost collision
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

collision ENDP
END
