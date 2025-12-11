TITLE gameState

INCLUDE Irvine32.inc

PUBLIC point, gameOverFlag, gameWinFlag
PUBLIC gameState

EXTERN playerX:DWORD, playerY:DWORD, dir:DWORD
EXTERN prevX:DWORD, prevY:DWORD
EXTERN ghostX:DWORD, ghostY:DWORD
EXTERN inputCode:DWORD
EXTERN waitToStartFlag:DWORD

resetMaze PROTO
PlayerReset PROTO

.data
point DWORD 0
gameOverMsg BYTE "GAME OVER",0
gameWinMsg BYTE "YOU WIN", 0
pressKeyMsg BYTE "Press any key to reset...", 0
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
    ; show the message of win
    mov edx, OFFSET gameWinMsg
    call WriteString
    call Crlf
    jmp timeInterval

GameOver:
    ; show the message of GameOver 
    mov edx, OFFSET gameOverMsg
    call WriteString
    call Crlf

timeInterval:
    ; wait for 1 seconds
    mov ecx, 1000
    call Delay

    ; press any key to restart
    mov edx, OFFSET pressKeyMsg
    call WriteString
    call Crlf

    call ReadChar
    call Clrscr

resetGame:
    xor eax, eax
    mov gameOverFlag, eax
    mov gameWinFlag, eax
    mov point, eax

    call PlayerReset
    
    mov eax, 26
    mov ghostX, eax
    mov eax, 4
    mov ghostY, eax
    
    call resetMaze
    
    mov eax, 1
    mov waitToStartFlag, eax

continueGame:
    ret

gameState ENDP
END
