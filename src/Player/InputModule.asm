TITLE InputModule

INCLUDE Irvine32.inc

EXTERN inputCode:DWORD

PUBLIC InputModule

.code
InputModule PROC

    mov dword ptr inputCode, 0

    call ReadKey
    jz input_end              ; Jump if Zero Flag set (no key pressed)

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
    
    ; Reset (R/r)
    cmp al, 'R'
    je setReset
    cmp al, 'r'
    je setReset

    jmp input_end

setForward:      
    mov inputCode, 1
    jmp input_end
setLeft:
    mov inputCode, 2
    jmp input_end
setBackward:
    mov inputCode, 3
    jmp input_end
setRight:
    mov inputCode, 4
    jmp input_end
setRotateLeft:   
    mov inputCode, 5
    jmp input_end
setRotateRight:  
    mov inputCode, 6
    jmp input_end
setReset:
    mov inputCode, 7
    jmp input_end

input_end:
    ret

InputModule ENDP
END