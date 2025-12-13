TITLE PlayerReset
INCLUDE Irvine32.inc

EXTERN playerX:DWORD, playerY:DWORD, dir:DWORD
EXTERN prevX:DWORD, prevY:DWORD

PUBLIC PlayerReset

.code
PlayerReset PROC

    mov playerX, 15       ; 回到初始位置
    mov playerY, 14
    mov prevX, 15
    mov prevY, 14
    mov dir, 0

    ret
PlayerReset ENDP

END