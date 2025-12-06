TITLE PlayerState

INCLUDE Irvine32.inc
PUBLIC PlayerState
PUBLIC playerX, playerY, dir, inputCode

EXTERN N:DWORD

.data
    playerX   DWORD 3
    playerY   DWORD 3
    dir       DWORD 1        ; 0=↑,1=→,2=↓,3=←
    inputCode DWORD 0        ; 0=none, 1~7

.code
; ------------------------------------
; PlayerState
; 回傳 (X,Y,Dir)
; eax = X, ebx = Y, ecx = dir
; ------------------------------------
PlayerState PROC
    mov eax, playerX
    mov ebx, playerY
    mov ecx, dir
    ret
PlayerState ENDP

END
