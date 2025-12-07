TITLE PlayerPos

INCLUDE Irvine32.inc

EXTERN inputCode:DWORD
EXTERN playerX:DWORD, playerY:DWORD, dir:DWORD
EXTERN N:DWORD

PUBLIC PlayerPos

.code
PlayerPos PROC
    mov eax, inputCode
    cmp eax, 1
    je wCase
    cmp eax, 2
    je aCase
    cmp eax, 3
    je sCase
    cmp eax, 4
    je dCase
    ret

;--------------- W ---------------
wCase:
    mov eax, dir
    cmp eax, 0
    je up
    cmp eax, 1
    je right
    cmp eax, 2
    je down
    cmp eax, 3
    je left
    ret

;--------------- S ---------------
sCase:
    mov eax, dir
    cmp eax, 0
    je down
    cmp eax, 1
    je left
    cmp eax, 2
    je up
    cmp eax, 3
    je right
    ret

;--------------- A ---------------
aCase:
    mov eax, dir
    cmp eax, 0
    je left
    cmp eax, 1
    je up
    cmp eax, 2
    je right
    cmp eax, 3
    je down
    ret

;--------------- D ---------------
dCase:
    mov eax, dir
    cmp eax, 0
    je right
    cmp eax, 1
    je down
    cmp eax, 2
    je left
    cmp eax, 3
    je up
    ret

;----------------------------------
up:
    mov eax, playerY
    cmp eax, 1
    jle pos_end
    dec playerY
    jmp pos_end

right:
    mov eax, playerX
    mov ecx, N
    cmp eax, ecx
    jge pos_end
    inc playerX
    jmp pos_end

down:
    mov eax, playerY
    mov ecx, N
    cmp eax, ecx
    jge pos_end
    inc playerY
    jmp pos_end

left:
    mov eax, playerX
    cmp eax, 1
    jle pos_end
    dec playerX
    jmp pos_end

pos_end:
    ret

PlayerPos ENDP
END
