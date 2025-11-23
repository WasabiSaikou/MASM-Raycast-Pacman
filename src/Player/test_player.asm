TITLE Player

INCLUDE Irvine32.inc
main    EQU start@0

;---------------------
;map: 
;(0,0) (1,0) (2,0) ....
;(0,1) ....

; 0=↑,1=→,2=↓,3=←
; 0=none,1=W,2=A,3=S,4=D,5=RotL,6=RotR,7=Reset
;---------------------

.data
         mapWidth  DWORD 7
         mapHeight DWORD 7

         playerX   DWORD 3
         playerY   DWORD 3
         dir       DWORD 1                                                                       ; 0=↑,1=→,2=↓,3=←
         inputCode DWORD 0                                                                       ; 0=none,1=W,2=A,3=S,4=D,5=RotL,6=RotR,7=Reset

         headerMsg BYTE "Player controller test (WASD move, <- -> rotate, R reset, Q quit)",0
         outFmt    BYTE "X=",0
         comma     BYTE "  Y=",0
         dirMsg    BYTE "  DIR=",0
         nl        BYTE 0Dh,0Ah,0

.code

    ; -------------------------
    ; main (測試用)
    ; -------------------------
main PROC
                     call Clrscr
                     mov  edx, OFFSET headerMsg
                     call WriteString
                     call Crlf

    mainLoop:        
                     call InputModule

    ; inputCode is movement type, call PlayerPos
                     mov  eax, inputCode
                     cmp  eax, 1
                     je   doMove
                     cmp  eax, 2
                     je   doMove
                     cmp  eax, 3
                     je   doMove
                     cmp  eax, 4
                     je   doMove

    ; inputCode is rotation type, call PlayerRotate
                     cmp  eax, 5
                     je   doRotate
                     cmp  eax, 6
                     je   doRotate

    ; Reset (7)
                     cmp  eax, 7
                     je   doReset

    ; invalid input
                     jmp  printState

    doMove:          
                     call PlayerPos
                     jmp  printState

    doRotate:        
                     call PlayerRotate
                     jmp  printState

    doReset:         
                     call PlayerReset
                     jmp  printState

    printState:      
                     call PlayerState
                     jmp  mainLoop

main ENDP

    ; -------------------------
    ; InputModule
    ; -------------------------
InputModule PROC
                     call ReadChar

    ; initial: 0
                     mov  dword ptr inputCode, 0

    ; Reset (R/r)
                     cmp  al, 'R'
                     je   setReset
                     cmp  al, 'r'
                     je   setReset

    ; WASD / wasd
                     cmp  al, 'W'
                     je   setForward
                     cmp  al, 'w'
                     je   setForward

                     cmp  al, 'A'
                     je   setLeft
                     cmp  al, 'a'
                     je   setLeft

                     cmp  al, 'S'
                     je   setBackward
                     cmp  al, 's'
                     je   setBackward

                     cmp  al, 'D'
                     je   setRight
                     cmp  al, 'd'
                     je   setRight

    ; arrow (<-, ->)
                     cmp  ax, 4B00h                 ; left arrow
                     je   setRotateLeft
                     cmp  ax, 4D00h                 ; right arrow
                     je   setRotateRight

                     ret

    ; set input codes
    setForward:      
                     mov  inputCode, 1
                     ret

    setLeft:         
                     mov  inputCode, 2
                     ret

    setBackward:     
                     mov  inputCode, 3
                     ret

    setRight:        
                     mov  inputCode, 4
                     ret

    setRotateLeft:   
                     mov  inputCode, 5
                     ret

    setRotateRight:  
                     mov  inputCode, 6
                     ret

    setReset:        
                     mov  inputCode, 7
                     ret

InputModule ENDP

    ; -------------------------
    ; PlayerPos
    ; Calculate all moves (1..4)
    ; 1=W,2=A,3=S,4=D
    ; Contains bounds checks
    ; -------------------------
PlayerPos PROC
                     mov  eax, inputCode
                     cmp  eax, 1
                     je   wCase
                     cmp  eax, 2
                     je   aCase
                     cmp  eax, 3
                     je   sCase
                     cmp  eax, 4
                     je   dCase
                     ret

    ; ---- W (move based on dir) ----
    ; dir: 0=↑,1=→,2=↓,3=←
    wCase:           
                     mov  eax, dir
                     cmp  eax, 0
                     je   up
                     cmp  eax, 1
                     je   right
                     cmp  eax, 2
                     je   down
                     cmp  eax, 3
                     je   left
                     jmp  pos_end

    ; ---- S (move based on dir) ----
    sCase:           
                     mov  eax, dir
                     cmp  eax, 0
                     je   down
                     cmp  eax, 1
                     je   left
                     cmp  eax, 2
                     je   up
                     cmp  eax, 3
                     je   right
                     jmp  pos_end

    ; ---- A (move based on dir) ----
    aCase:           
                     mov  eax, dir
                     cmp  eax, 0
                     je   left
                     cmp  eax, 1
                     je   up
                     cmp  eax, 2
                     je   right
                     cmp  eax, 3
                     je   down
                     jmp  pos_end

    ; ---- D (move based on dir) ----
    dCase:           
                     mov  eax, dir
                     cmp  eax, 0
                     je   right
                     cmp  eax, 1
                     je   down
                     cmp  eax, 2
                     je   left
                     cmp  eax, 3
                     je   up
                     jmp  pos_end

    up:              
                     mov  eax, playerY
                     cmp  eax, 1
                     jle  pos_end                   ; if y<=1, it is already at the boundary, so it doesn't move.
                     dec  playerY
                     jmp  pos_end

    right:           
                     mov  eax, playerX
                     mov  ecx, mapWidth
                     sub  ecx, 1
                     cmp  eax, ecx
                     jge  pos_end                   ; if x>=mapWidth, it is already at the boundary, so it doesn't move.
                     inc  playerX
                     jmp  pos_end

    down:            
                     mov  eax, playerY
                     mov  ecx, mapHeight
                     sub  ecx, 1
                     cmp  eax, ecx
                     jge  pos_end                   ; if y>=mapHeight, it is already at the boundary, so it doesn't move.
                     inc  playerY
                     jmp  pos_end

    left:            
                     mov  eax, playerX
                     cmp  eax, 1
                     jle  pos_end                   ; if x<=1, it is already at the boundary, so it doesn't move.
                     dec  playerX
                     jmp  pos_end

    pos_end:         
                     ret
PlayerPos ENDP

    ; -------------------------
    ; PlayerRotate
    ; inputCode = 5 => left, 6 => right
    ; -------------------------
PlayerRotate PROC
                     mov  eax, inputCode
                     cmp  eax, 5
                     je   rotateLeftLabel
                     cmp  eax, 6
                     je   rotateRightLabel
                     ret

    rotateLeftLabel: 
                     mov  eax, dir
                     add  eax, 3                    ; (dir - 1 + 4) % 4
                     and  eax, 3
                     mov  dir, eax
                     ret

    rotateRightLabel:
                     mov  eax, dir
                     inc  eax                       ; (dir + 1) % 4
                     and  eax, 3
                     mov  dir, eax
                     ret

PlayerRotate ENDP

    ; -------------------------
    ; PlayerReset
    ; -------------------------
PlayerReset PROC
                     mov  playerX, 3
                     mov  playerY, 3
                     mov  dir, 1
                     ret
PlayerReset ENDP

    ; -------------------------
    ; PlayerState (測試輸出)
    ; -------------------------
PlayerState PROC
                     mov  edx, OFFSET outFmt
                     call WriteString
                     mov  eax, playerX
                     call WriteDec

                     mov  edx, OFFSET comma
                     call WriteString
                     mov  eax, playerY
                     call WriteDec

                     mov  edx, OFFSET dirMsg
                     call WriteString
                     mov  eax, dir
                     call WriteDec

                     mov  edx, OFFSET nl
                     call WriteString
                     ret
PlayerState ENDP

END main


