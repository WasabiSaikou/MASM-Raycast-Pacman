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

drawMaze BYTE 32 DUP (32 DUP (?))
; █ : 219(DBh) -> wall
; ● : 250(FAh) -> dot
;   : 32 (20h) -> path
; ☺ : 01h player 
; ♠ : 06h ghost


.code
render2D PROC
    ; clear the screen
    call Clrscr

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
    ret

showLoseMsg:
    mov edx, OFFSET gameOverMsg
    call WriteString
    call Crlf
    ret

showResetMsg:
    mov edx, OFFSET pressKeyMsg
    call WriteString
    call Crlf
    ret

; ----------------------------------
;        print game message
; ----------------------------------
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

    ; print point
    mov edx, OFFSET pointMsg
    call WriteString
    mov eax, point
    call WriteDec
    call Crlf
    call Crlf

; ----------------------------------
;          set output Maze
; ----------------------------------
    mov ecx, MazeSize        ; all elements that we need to initialize
    mov esi, OFFSET drawMaze
    mov edi, OFFSET MazeMap
    
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
    mov BYTE PTR [edi], 219
    jmp increaseAddr
setDot:
    mov BYTE PTR [edi], 250    
    jmp increaseAddr
increaseAddr:
    inc esi
    inc edi
    loop copyLoop


setPlayer:
    ; index = N * playerY + playerX
    mov eax, playerY
    imul eax, N
    mov edx, playerX
    add eax, edx                   ; eax = index
    mov esi, OFFSET MazeMap
    mov BYTE PTR [esi + eax], 1

setGhost:
    ; index = N * ghostY + ghostX
    mov eax, ghostY
    imul eax, N
    mov edx, ghostX
    add eax, edx                   ; eax = index
    mov esi, OFFSET MazeMap
    mov BYTE PTR [esi + eax], 6

; ----------------------------------
;            print Maze
; ----------------------------------
    mov esi, OFFSET drawMaze
    mov ecx, N    ; row loop

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