TITLE PlayerReset
INCLUDE Irvine32.inc

EXTERN playerX:DWORD, playerY:DWORD, dir:DWORD
EXTERN inputCode:DWORD

PUBLIC PlayerReset

.code
PlayerReset PROC

    mov eax, inputCode
    cmp eax, 7           ; inputCode = 7 表示 Reset
    jne reset_end

    mov playerX, 3       ; 回到初始位置
    mov playerY, 3
    mov dir, 1           ; 初始朝向：右（你的原始設定）

reset_end:
    ret
PlayerReset ENDP

END
