TITLE PlayerRotate

INCLUDE Irvine32.inc

EXTERN dir:DWORD
EXTERN inputCode:DWORD

PUBLIC PlayerRotate

.code
PlayerRotate PROC
    mov eax, inputCode
    cmp eax, 5
    je rotateLeft
    cmp eax, 6
    je rotateRight
    ret

rotateLeft:
    mov eax, dir
    add eax, 3            ; (dir - 1 + 4) % 4
    and eax, 3
    mov dir, eax
    ret

rotateRight:
    mov eax, dir
    inc eax               ; (dir + 1) % 4
    and eax, 3
    mov dir, eax
    ret

PlayerRotate ENDP
END
