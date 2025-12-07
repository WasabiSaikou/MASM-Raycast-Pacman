TITLE PlayerState

INCLUDE Irvine32.inc
PUBLIC PlayerState
PUBLIC playerX, playerY, dir, inputCode
PUBLIC moveState
PUBLIC prevX, prevY

EXTERN N:DWORD

.data
    playerX   DWORD 16
    playerY   DWORD 15
    dir       DWORD 1        ; 0=↑,1=→,2=↓,3=←
    inputCode DWORD 0        ; 0=none, 1~7
    moveState DWORD 0        ; 0 = stop, 1 = frond, 2 = left, 3 = behind, 4 = right
    prevX     DWORD 16
    prevY     DWORD 15

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
