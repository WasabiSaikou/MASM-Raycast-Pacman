TITLE InputModule

INCLUDE Irvine32.inc

EXTERN inputCode:DWORD
EXTERN moveState:DWORD

PUBLIC InputModule

.code
InputModule PROC

    mov eax, dword ptr moveState
    mov dword ptr inputCode, 0

    call ReadKey

    ; Reset (R/r)
    cmp al, 'R'
    je setReset
    cmp al, 'r'
    je setReset

    ; WASD
    cmp al, 'W'
    je setForward
    cmp al, 'w'
    je setForward

    cmp al, 'A'
    je setLeft
    cmp al, 'a'
    je setLeft

    cmp al, 'S'
    je setBackward
    cmp al, 's'
    je setBackward

    cmp al, 'D'
    je setRight
    cmp al, 'd'
    je setRight

    cmp  ax, 4B00h                 ; left arrow
    je   setRotateLeft
    cmp  ax, 4D00h                 ; right arrow
    je   setRotateRight

    jmp input_end

setForward:      
    mov inputCode, 1
    mov moveState, 1
    ret
setLeft:
    mov inputCode, 2
    mov moveState, 2
    ret
setBackward:
    mov inputCode, 3
    mov moveState, 3
    ret
setRight:
    mov inputCode, 4
    mov moveState, 4
    ret
setRotateLeft:   
    mov  inputCode, 5
    ret
setRotateRight:  
    mov  inputCode, 6
    ret
setReset:        
    mov  inputCode, 7
    mov  moveState, 0
    ret

input_end:
    ret

InputModule ENDP
END
