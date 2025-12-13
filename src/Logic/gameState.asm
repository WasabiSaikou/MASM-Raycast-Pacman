TITLE gameState

INCLUDE Irvine32.inc

PUBLIC point, gameStateFlag, resultDisplayTimer
PUBLIC gameState
PUBLIC gameOverMsg, gameWinMsg, pressKeyMsg

EXTERN playerX:DWORD, playerY:DWORD, dir:DWORD
EXTERN prevX:DWORD, prevY:DWORD
EXTERN ghostX:DWORD, ghostY:DWORD
EXTERN inputCode:DWORD
;EXTERN waitToStartFlag:DWORD
EXTERN tickMs:DWORD

resetMaze PROTO
PlayerReset PROTO
GhostReset PROTO

.data
point DWORD 0
gameOverMsg BYTE "GAME OVER",0
gameWinMsg BYTE "YOU WIN", 0
pressKeyMsg BYTE "Press any key to reset...", 0

; 0: playing, 1: win, 2: lose, 3: show win message, 4: show lose message, 5: reset game
gameStateFlag DWORD 0       
resultDisplayTimer DWORD 0  ; A timer used to count down 1000ms

.code
gameState PROC
    mov eax, gameStateFlag
    cmp eax, 0
    je continueGame

    ; check if win the game
    cmp eax, 1
    je Win

    ; check if game over
    cmp eax, 2
    je GameOver

    ; check if is showing the message
    cmp eax, 3
    je continueGame
    cmp eax, 4
    je continueGame

    jmp resetGame

Win:
    ; show the message of win
    mov ebx, 3
    mov gameStateFlag, ebx
    mov resultDisplayTimer, 1000  ; set 1000ms
    ret

GameOver:
    ; show the message of GameOver 
    mov ebx, 4
    mov gameStateFlag, ebx
    mov resultDisplayTimer, 1000  ; set 1000ms
    ret

resetGame:
    xor eax, eax
    mov gameStateFlag, eax
    mov point, eax

    call PlayerReset
    call GhostReset
    call resetMaze
    
    ;mov eax, 1
    ;mov waitToStartFlag, eax

continueGame:
    ret
gameState ENDP

END
