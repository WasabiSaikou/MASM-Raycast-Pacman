TITLE gameState

INCLUDE Irvine32.inc

PUBLIC point, gameOverFlag, gameWinFlag
PUBLIC gameState

EXTERN playerX:DWORD, playerY:DWORD, dir:DWORD
EXTERN prevX:DWORD, prevY:DWORD
EXTERN ghostX:DWORD, ghostY:DWORD

EXTERN resetMaze:PROC
EXTERN PlayerReset:PROC

.data
point DWORD 0
gameOverMsg BYTE "GAME OVER",0
gameWinMsg BYTE "YOU WIN", 0
gameOverFlag DWORD 0
gameWinFlag DWORD 0

.code
gameState PROC
    ; check if win the game
    mov eax, gameWinFlag
    cmp eax, 1
    je Win

    ; check if game over
    mov eax, gameOverFlag
    cmp eax, 1
    jne continueGame
    jmp GameOver

Win:
    mov edx, OFFSET gameWinMsg
    call WriteString
    call Crlf
    jmp timeInterval

GameOver:
    ; 顯示 GameOver 訊息
    mov edx, OFFSET gameOverMsg
    call WriteString
    call Crlf

timeInterval:
    ; 暫停 3 秒
    mov eax, 3000
    call Delay

resetGame:
    xor eax, eax
    mov gameOverFlag, eax
    mov gameWinFlag, eax
    mov point, eax

    call PlayerReset
    
    mov eax, 27
    mov ghostX, eax
    mov eax, 5
    mov ghostY, eax
    
    call resetMaze

continueGame:
    ret

gameState ENDP
END
