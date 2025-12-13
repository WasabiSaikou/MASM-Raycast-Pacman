TITLE render2D

Include Irvine32.inc

EXTERN MazeMap:BYTE, N:DWORD, MazeSize:DWORD
EXTERN ghostX:DWORD, ghostY:DWORD
EXTERN playerX:DWORD, playerY:DWORD, dir:DWORD, point:DWORD

EXTERN gameStateFlag:DWORD, gameOverMsg:DWORD, gameWinMsg:DWORD, pressKeyMsg:DWORD

PUBLIC render2D

.data
playerXMsg  BYTE "playerX=",0
playerYMsg  BYTE ", playerY=",0
dirMsg BYTE ", DIR=",0
ghostXMsg  BYTE "ghostX=",0
ghostYMsg  BYTE ", ghostY=",0
pointMsg BYTE "point=",0

drawMaze BYTE 1024 DUP (?)
; # : 35 -> wall
; . : 46 -> dot
;   : 32 -> path
; @ : 64 -> player 
; G : 71 -> ghost


.code
render2D PROC
    mov dh, 0
    mov dl, 0
    call Gotoxy

    ; check gameStateFlag
    mov eax, gameStateFlag
    cmp eax, 3
    je showWinMsg
    cmp eax, 4
    je showLoseMsg
    cmp eax, 5
    je showResetMsg
    jmp printGame

showWinMsg:
    mov edx, OFFSET gameWinMsg
    call WriteString
    call Crlf
    mov edx, OFFSET pressKeyMsg
    call WriteString
    call Crlf
    ret

showLoseMsg:
    mov edx, OFFSET gameOverMsg
    call WriteString
    call Crlf
    mov edx, OFFSET pressKeyMsg
    call WriteString
    call Crlf
    ret

showResetMsg:
    mov edx, OFFSET pressKeyMsg
    call WriteString
    mov ecx, 50
clearLoop3:
    mov al, ' '
    call WriteChar
    loop clearLoop3
    call Crlf
    ret

printGame:
    ; print playerX
    mov edx, OFFSET playerXMsg
    call WriteString
    mov eax, playerX
    call WriteDec

    ; print playerY
    mov edx, OFFSET playerYMsg
    call WriteString
    mov eax, playerY
    call WriteDec

    ; print dir
    mov edx, OFFSET dirMsg
    call WriteString
    mov eax, dir
    call WriteDec
    call Crlf

    ; print ghostX
    mov edx, OFFSET ghostXMsg
    call WriteString
    mov eax, ghostX
    call WriteDec

    ; print ghostY
    mov edx, OFFSET ghostYMsg
    call WriteString
    mov eax, ghostY
    call WriteDec
    call Crlf

    ; print point with leading zeros (3 digits: 000-361)
    mov edx, OFFSET pointMsg
    call WriteString
    
    ; Display points with leading zeros
    mov eax, point
    
    ; Print hundreds digit
    mov ebx, 100
    xor edx, edx
    div ebx                    ; EAX = hundreds, EDX = remainder
    add al, '0'
    call WriteChar
    
    ; Print tens digit
    mov eax, edx               ; Remainder from previous division
    mov ebx, 10
    xor edx, edx
    div ebx                    ; EAX = tens, EDX = ones
    add al, '0'
    call WriteChar
    
    ; Print ones digit
    mov eax, edx
    add al, '0'
    call WriteChar
    
    call Crlf
    call Crlf

; ----------------------------------
;     Copy MazeMap to drawMaze
; ----------------------------------
    mov ecx, MazeSize
    mov esi, OFFSET MazeMap
    mov edi, OFFSET drawMaze
    
copyLoop:
    mov al, [esi]
    cmp al, 0
    je setPath
    cmp al, 1
    je setWall
    jmp setDot
    
setPath:
    mov BYTE PTR [edi], 32
    jmp increaseAddr
setWall:
    mov BYTE PTR [edi], 35
    jmp increaseAddr
setDot:
    mov BYTE PTR [edi], 46
    
increaseAddr:
    inc esi
    inc edi
    loop copyLoop

; ----------------------------------
;   Overlay player and ghost (0-BASED)
; ----------------------------------
setPlayer:
    ; index = playerY * N + playerX (0-based, no dec!)
    mov eax, playerY
    imul eax, N
    mov edx, playerX
    add eax, edx
    mov esi, OFFSET drawMaze
    mov BYTE PTR [esi + eax], 64  ; '@'

setGhost:
    ; index = ghostY * N + ghostX (0-based, no dec!)
    mov eax, ghostY
    imul eax, N
    mov edx, ghostX
    add eax, edx
    mov esi, OFFSET drawMaze
    mov BYTE PTR [esi + eax], 71  ; 'G'

; ----------------------------------
;     Display
; ----------------------------------
    mov esi, OFFSET drawMaze
    mov ecx, N

RowLoop:
    push ecx
    mov ecx, N

ColumnLoop:
    mov al, [esi]
    call WriteChar
    inc esi
    loop ColumnLoop

    call Crlf
    pop ecx
    loop RowLoop

    ret
render2D ENDP

END